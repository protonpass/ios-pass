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
import Factory
import MBProgressHUD
import ProtonCore_Authentication
import ProtonCore_FeatureSwitch
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import ProtonCore_Utilities
import SwiftUI
import UIComponents
import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private let appStateObserver: AppStateObserver
    private var container: NSPersistentContainer
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
    private let credentialManager = resolve(\SharedServiceContainer.credentialManager)

    // Use cases
    private let checkAccessToPass = resolve(\UseCasesContainer.checkAccessToPass)

    init(window: UIWindow) {
        self.window = window
        appStateObserver = .init()

        container = .Builder.build(name: kProtonPassContainerName,
                                   inMemory: false)
        isUITest = false
        clearUserDataInKeychainIfFirstRun()
        bindAppState()

        // if ui test reset everything
        if ProcessInfo.processInfo.arguments.contains("RunningInUITests") {
            isUITest = true
            wipeAllData(includingUnauthSession: true)
        }
        apiManager.delegate = self
    }

    private func clearUserDataInKeychainIfFirstRun() {
        guard preferences.isFirstRun else { return }
        preferences.isFirstRun = false
        appData.userData = nil
    }

    private func bindAppState() {
        appStateObserver.$appState
            .receive(on: DispatchQueue.main)
            .dropFirst() // Don't react to default undefined state
            .sink { [weak self] appState in
                guard let self else { return }
                switch appState {
                case let .loggedOut(reason):
                    self.logger.info("Logged out \(reason)")
                    let shouldWipeUnauthSession = reason != .noAuthSessionButUnauthSessionAvailable
                    self.wipeAllData(includingUnauthSession: shouldWipeUnauthSession)
                    self.showWelcomeScene(reason: reason)

                case let .loggedIn(userData, manualLogIn):
                    self.logger.info("Logged in manual \(manualLogIn)")
                    self.appData.userData = userData
                    self.apiManager.sessionIsAvailable(authCredential: userData.credential,
                                                       scopes: userData.scopes)
                    self.showHomeScene(userData: userData, manualLogIn: manualLogIn)
                    if manualLogIn {
                        self.checkAccessToPass()
                    }

                case .undefined:
                    self.logger.warning("Undefined app state. Don't know what to do...")
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        if let userData = appData.userData {
            appStateObserver.updateAppState(.loggedIn(userData: userData, manualLogIn: false))
        } else if appData.unauthSessionCredentials != nil {
            appStateObserver.updateAppState(.loggedOut(.noAuthSessionButUnauthSessionAvailable))
        } else {
            appStateObserver.updateAppState(.loggedOut(.noSessionDataAtAll))
        }
    }

    func showLoadingHud() {
        guard let view = window.rootViewController?.view else { return }
        MBProgressHUD.showAdded(to: view, animated: true)
    }

    func hideLoadingHud() {
        guard let view = window.rootViewController?.view else { return }
        MBProgressHUD.hide(for: view, animated: true)
    }

    private func showWelcomeScene(reason: LogOutReason) {
        let welcomeCoordinator = WelcomeCoordinator(apiService: apiManager.apiService,
                                                    preferences: preferences)
        welcomeCoordinator.delegate = self
        self.welcomeCoordinator = welcomeCoordinator
        homepageCoordinator = nil
        animateUpdateRootViewController(welcomeCoordinator.rootViewController) { [unowned self] in
            switch reason {
            case .expiredRefreshToken:
                alertRefreshTokenExpired()
            case .failedBiometricAuthentication:
                alertFailedBiometricAuthentication()
            case .sessionInvalidated:
                alertSessionInvalidated()
            default:
                break
            }
        }
    }

    private func showHomeScene(userData: UserData, manualLogIn: Bool) {
        do {
            let symmetricKey = try appData.getSymmetricKey()

            SharedDataContainer.shared.reset()
            SharedDataContainer.shared.register(container: container,
                                                symmetricKey: symmetricKey,
                                                userData: userData,
                                                manualLogIn: manualLogIn)
            SharedToolingContainer.shared.resetCache()
            SharedRepositoryContainer.shared.reset()
            SharedServiceContainer.shared.reset()

            let homepageCoordinator = HomepageCoordinator()
            homepageCoordinator.delegate = self
            self.homepageCoordinator = homepageCoordinator
            welcomeCoordinator = nil
            animateUpdateRootViewController(homepageCoordinator.rootViewController) {
                homepageCoordinator.onboardIfNecessary()
            }
        } catch {
            logger.error(error)
            wipeAllData(includingUnauthSession: true)
            appStateObserver.updateAppState(.loggedOut(.failedToGenerateSymmetricKey))
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
        appData.userData = nil
        if includingUnauthSession {
            apiManager.clearCredentials()
            mainKeyProvider.wipeMainKey()
        }
        preferences.reset(isTests: isUITest)
        Task { [weak self] in
            guard let self else { return }
            // Do things independently in different `do catch` blocks
            // because we don't want a failed operation prevents others from running
            do {
                try await self.credentialManager.removeAllCredentials()
                self.logger.info("Removed all credentials")
            } catch {
                self.logger.error(error)
            }

            do {
                // Delete existing persistent stores
                let storeContainer = self.container.persistentStoreCoordinator
                for store in storeContainer.persistentStores {
                    if let url = store.url {
                        try storeContainer.destroyPersistentStore(at: url, ofType: store.type)
                    }
                }

                // Re-create persistent container
                self.container = .Builder.build(name: kProtonPassContainerName, inMemory: false)
                self.logger.info("Nuked local data")
            } catch {
                self.logger.error(error)
            }
        }
    }

    private func alertRefreshTokenExpired() {
        let alert = UIAlertController(title: "Your session is expired",
                                      message: "Please log in again",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        rootViewController?.present(alert, animated: true)
    }
}

// MARK: - WelcomeCoordinatorDelegate

extension AppCoordinator: WelcomeCoordinatorDelegate {
    func welcomeCoordinator(didFinishWith userData: LoginData) {
        appStateObserver.updateAppState(.loggedIn(userData: userData, manualLogIn: true))
    }

    private func alertSessionInvalidated() {
        let alert = UIAlertController(title: "Error occured",
                                      message: "Your session was invalidated",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        rootViewController?.present(alert, animated: true)
    }

    private func alertFailedBiometricAuthentication() {
        let alert = UIAlertController(title: "Failed to authenticate",
                                      message: "You have to log in again in order to continue using Proton Pass",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        rootViewController?.present(alert, animated: true)
    }
}

// MARK: - APIManagerDelegate

extension AppCoordinator: APIManagerDelegate {
    func appLoggedOutBecauseSessionWasInvalidated() {
        // Run on main thread because the callback that triggers this function
        // is returned by `AuthHelperDelegate` from background thread
        DispatchQueue.main.async {
            self.appStateObserver.updateAppState(.loggedOut(.sessionInvalidated))
        }
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
