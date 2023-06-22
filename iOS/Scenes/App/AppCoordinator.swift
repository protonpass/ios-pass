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
    private let keymaker: Keymaker
    private let appData: AppData
    private let apiManager: APIManager
    private let logManager: LogManager
    private let logger: Logger
    private var container: NSPersistentContainer
    private let credentialManager: CredentialManagerProtocol
    private var preferences: Preferences
    private var isUITest: Bool
    private let appVersion = "ios-pass@\(Bundle.main.fullAppVersionName)"

    private var homepageCoordinator: HomepageCoordinator?
    private var welcomeCoordinator: WelcomeCoordinator?

    private var rootViewController: UIViewController? { window.rootViewController }

    private var appLockedViewController: UIViewController?
    private var autolocker: Autolocker?

    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow) {
        self.window = window
        appStateObserver = .init()
        logManager = ToolingContainer.shared.hostAppLogManager()
        logger = ToolingContainer.shared.mainAppLoger()
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        let appData = AppData(keychain: keychain, mainKeyProvider: keymaker, logManager: logManager)
        self.appData = appData
        self.keymaker = keymaker
        let preferences = Preferences()
        let apiManager = APIManager(logManager: logManager,
                                    appVer: appVersion,
                                    appData: appData,
                                    preferences: preferences)
        self.apiManager = apiManager
        container = .Builder.build(name: kProtonPassContainerName,
                                   inMemory: false)
        credentialManager = CredentialManager(logManager: logManager)
        self.preferences = preferences
        isUITest = false
        clearUserDataInKeychainIfFirstRun()
        bindAppState()

        // if ui test reset everything
        if ProcessInfo.processInfo.arguments.contains("RunningInUITests") {
            isUITest = true
            wipeAllData(includingUnauthSession: true)
        }
        self.apiManager.delegate = self
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

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                // Make sure preferences are up to date
                self.preferences = .init()
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
        Task { @MainActor in
            do {
                let apiService = self.apiManager.apiService
                let symmetricKey = try self.appData.getSymmetricKey()
                let homepageCoordinator = HomepageCoordinator(apiService: apiService,
                                                              container: container,
                                                              credentialManager: credentialManager,
                                                              logManager: logManager,
                                                              manualLogIn: manualLogIn,
                                                              preferences: preferences,
                                                              symmetricKey: symmetricKey,
                                                              userData: userData,
                                                              appData: appData,
                                                              mainKeyProvider: keymaker)
                homepageCoordinator.delegate = self
                self.homepageCoordinator = homepageCoordinator
                self.welcomeCoordinator = nil
                animateUpdateRootViewController(homepageCoordinator.rootViewController) {
                    homepageCoordinator.onboardIfNecessary()
                }
            } catch {
                logger.error(error)
                wipeAllData(includingUnauthSession: true)
                appStateObserver.updateAppState(.loggedOut(.failedToGenerateSymmetricKey))
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
        appData.userData = nil
        autolocker?.releaseCountdown()
        autolocker = nil
        if includingUnauthSession {
            apiManager.clearCredentials()
            keymaker.wipeMainKey()
        }
        preferences.reset(isUITests: isUITest)
        Task {
            // Do things independently in different `do catch` blocks
            // because we don't want a failed operation prevents others from running
            do {
                try await credentialManager.removeAllCredentials()
                logger.info("Removed all credentials")
            } catch {
                logger.error(error)
            }

            do {
                // Delete existing persistent stores
                let storeContainer = container.persistentStoreCoordinator
                for store in storeContainer.persistentStores {
                    if let url = store.url {
                        try storeContainer.destroyPersistentStore(at: url, ofType: store.type)
                    }
                }

                // Re-create persistent container
                container = .Builder.build(name: kProtonPassContainerName, inMemory: false)
                logger.info("Nuked local data")
            } catch {
                logger.error(error)
            }
        }
    }

    /// Inform the BE that the users had logged in into Pass
    /// so that welcome or instruction emails can be sent
    private func checkAccessToPass() {
        Task {
            do {
                logger.trace("Checking access to Pass")
                let endpoint = CheckAccessAndPlanEndpoint()
                _ = try await apiManager.apiService.exec(endpoint: endpoint)
                logger.info("Checked access to Pass")
            } catch {
                logger.error(error)
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
        guard userData.scopes.contains("pass") else {
            // try refreshing the credentials
            // this is a workaround for the fact that the user with access to pass won't get the pass scope
            // if their account lacks keys — however, after the credentials refresh, the scope is properly set
            apiManager.apiService.refreshCredential(userData.getCredential) { result in
                switch result {
                case let .success(refreshedCredentials) where refreshedCredentials.scopes.contains("pass"):
                    self.apiManager.apiService.setSessionUID(uid: refreshedCredentials.UID)
                    self.apiManager.authHelper.onSessionObtaining(credential: refreshedCredentials)
                    self.appStateObserver.updateAppState(.loggedIn(userData: userData, manualLogIn: true))
                case .failure, .success:
                    self.appData.userData = nil
                    self.apiManager.clearCredentials()
                    self.alertNoPassScope()
                }
            }
            return
        }
        appStateObserver.updateAppState(.loggedIn(userData: userData, manualLogIn: true))
    }

    private func alertNoPassScope() {
        // swiftlint:disable line_length
        let alert = UIAlertController(title: "Error occured",
                                      message: "You are not eligible for using this application. Please contact our customer service.",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        rootViewController?.present(alert, animated: true)
        // swiftlint:enable line_length
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
