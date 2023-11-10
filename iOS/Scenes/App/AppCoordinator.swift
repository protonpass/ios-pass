//
// AppCoordinator.swift
// Proton Pass - Created on 02/07/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import Client
import Combine
import Core
import CoreData
import CryptoKit
import DesignSystem
import Entities
import Factory
import Macro
import MBProgressHUD
import ProtonCoreAuthentication
import ProtonCoreFeatureSwitch
import ProtonCoreKeymaker
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreServices
import ProtonCoreUtilities
import Sentry
import SwiftUI
import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private let appStateObserver: AppStateObserver
    private var isUITest: Bool

    private var homepageCoordinator: HomepageCoordinator?
    private var welcomeCoordinator: WelcomeCoordinator?

    private var rootViewController: UIViewController? { window.rootViewController }

    private var cancellables = Set<AnyCancellable>()

    private var preferences = resolve(\SharedToolingContainer.preferences)
    private let mainKeyProvider = resolve(\SharedToolingContainer.mainKeyProvider)
    private let appData = resolve(\SharedDataContainer.appData)
    private let apiManager = resolve(\SharedToolingContainer.apiManager)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)

    init(window: UIWindow) {
        self.window = window
        appStateObserver = .init()

        isUITest = false
        clearUserDataInKeychainIfFirstRun()
        bindAppState()

        // if ui test reset everything
        if ProcessInfo.processInfo.arguments.contains("RunningInUITests") {
            isUITest = true
            wipeAllData(includingUnauthSession: true)
        }

        apiManager.sessionWasInvalidated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
  				SentrySDK.capture(error: PassError.unexpectedLogout)
                // swiftlint:disable:next discouraged_optional_self
                self?.appStateObserver.updateAppState(.loggedOut(.sessionInvalidated))
            }.store(in: &cancellables)
    }

    private func clearUserDataInKeychainIfFirstRun() {
        guard preferences.isFirstRun else { return }
        preferences.isFirstRun = false
        appData.setUserData(nil)
    }

    private func bindAppState() {
        appStateObserver.$appState
            .receive(on: DispatchQueue.main)
            .dropFirst() // Don't react to default undefined state
            .sink { [weak self] appState in
                guard let self else { return }
                switch appState {
                case let .loggedOut(reason):
                    logger.info("Logged out \(reason)")
                    let shouldWipeUnauthSession = reason != .noAuthSessionButUnauthSessionAvailable
                    wipeAllData(includingUnauthSession: shouldWipeUnauthSession)
                    showWelcomeScene(reason: reason)

                case let .loggedIn(userData, manualLogIn):
                    logger.info("Logged in manual \(manualLogIn)")
                    if manualLogIn {
                        // Only update userData when manually log in
                        // because otherwise we'd just rewrite the same userData object
                        appData.setUserData(userData)
                    }
                    apiManager.sessionIsAvailable(authCredential: userData.credential,
                                                  scopes: userData.scopes)
                    showHomeScene(manualLogIn: manualLogIn)

                case .undefined:
                    logger.warning("Undefined app state. Don't know what to do...")
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        if let userData = appData.getUserData() {
            appStateObserver.updateAppState(.loggedIn(userData: userData, manualLogIn: false))
        } else if appData.getUnauthCredential() != nil {
            appStateObserver.updateAppState(.loggedOut(.noAuthSessionButUnauthSessionAvailable))
        } else {
            appStateObserver.updateAppState(.loggedOut(.noSessionDataAtAll))
        }
    }

    private func showWelcomeScene(reason: LogOutReason) {
        let welcomeCoordinator = WelcomeCoordinator(apiService: apiManager.apiService,
                                                    preferences: preferences)
        welcomeCoordinator.delegate = self
        self.welcomeCoordinator = welcomeCoordinator
        homepageCoordinator = nil
        animateUpdateRootViewController(welcomeCoordinator.rootViewController) { [weak self] in
            guard let self else { return }
            handle(logOutReason: reason)
        }
    }

    private func showHomeScene(manualLogIn: Bool) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            await loginMethod.setLogInFlow(newState: manualLogIn)
            let homepageCoordinator = HomepageCoordinator()
            homepageCoordinator.delegate = self
            self.homepageCoordinator = homepageCoordinator
            welcomeCoordinator = nil
            animateUpdateRootViewController(homepageCoordinator.rootViewController) {
                homepageCoordinator.onboardIfNecessary()
            }
        }
    }

    private func animateUpdateRootViewController(_ newRootViewController: UIViewController,
                                                 completion: (() -> Void)? = nil) {
        window.rootViewController = newRootViewController
        UIView.transition(with: window,
                          duration: 0.35,
                          options: .transitionCrossDissolve,
                          animations: nil) { _ in completion?() }
    }

    private func wipeAllData(includingUnauthSession: Bool) {
        logger.info("Wiping all data, includingUnauthSession: \(includingUnauthSession)")
        appData.resetData()
        mainKeyProvider.wipeMainKey()
        if includingUnauthSession {
            apiManager.clearCredentials()
        }
        preferences.reset(isTests: isUITest)
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await SharedServiceContainer.shared.reset()
                SharedViewContainer.shared.reset()
            } catch {
                logger.error(error)
            }
        }
    }
}

private extension AppCoordinator {
    /// Show an alert with a single "OK" button that does nothing
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: #localized("OK"), style: .default))
        rootViewController?.present(alert, animated: true)
    }

    func handle(logOutReason: LogOutReason) {
        switch logOutReason {
        case .expiredRefreshToken, .sessionInvalidated:
            alert(title: #localized("Your session is expired"),
                  message: #localized("Please log in again"))
        case .failedBiometricAuthentication:
            alert(title: #localized("Failed to authenticate"),
                  message: #localized("Please log in again"))
        default:
            break
        }
    }
}

// MARK: - WelcomeCoordinatorDelegate

extension AppCoordinator: WelcomeCoordinatorDelegate {
    func welcomeCoordinator(didFinishWith userData: LoginData) {
        appStateObserver.updateAppState(.loggedIn(userData: userData, manualLogIn: true))
    }
}

// MARK: - HomepageCoordinatorDelegate

extension AppCoordinator: HomepageCoordinatorDelegate {
    func homepageCoordinatorWantsToLogOut() {
        appStateObserver.updateAppState(.loggedOut(.userInitiated))
    }

    func homepageCoordinatorDidFailLocallyAuthenticating() {
        appStateObserver.updateAppState(.loggedOut(.failedBiometricAuthentication))
    }
}
