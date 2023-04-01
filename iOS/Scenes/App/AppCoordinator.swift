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
import GoLibs
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
    private let apiManager: APIManager
    private let logManager: LogManager
    private let logger: Logger
    private var container: NSPersistentContainer
    private let credentialManager: CredentialManagerProtocol
    private var preferences: Preferences
    private var isUITest: Bool
    private let appVersion = "ios-pass@\(Bundle.main.fullAppVersionName())"

    @KeychainStorage(key: .authSessionData)
    private var sessionData: SessionData?

    @KeychainStorage(key: .unauthSessionCredentials)
    private var unauthSessionCredentials: AuthCredential?

    @KeychainStorage(key: .symmetricKey)
    private var symmetricKey: String?

    private var homepageCoordinator: HomepageCoordinator?
    private var welcomeCoordinator: WelcomeCoordinator?

    private var rootViewController: UIViewController? { window.rootViewController }

    private var appLockedViewController: UIViewController?

    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow) {
        self.window = window
        self.appStateObserver = .init()
        self.logManager = .init(module: .hostApp)
        self.logger = .init(manager: self.logManager)
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        self._sessionData.setKeychain(keychain)
        self._sessionData.setMainKeyProvider(keymaker)
        self._sessionData.setLogManager(self.logManager)
        self._unauthSessionCredentials.setKeychain(keychain)
        self._unauthSessionCredentials.setMainKeyProvider(keymaker)
        self._unauthSessionCredentials.setLogManager(self.logManager)
        self._symmetricKey.setKeychain(keychain)
        self._symmetricKey.setMainKeyProvider(keymaker)
        self._symmetricKey.setLogManager(self.logManager)
        self.keymaker = keymaker
        self.apiManager = APIManager(keychain: keychain,
                                     mainKeyProvider: keymaker,
                                     logManager: logManager,
                                     appVer: appVersion)
        self.container = .Builder.build(name: kProtonPassContainerName,
                                        inMemory: false)
        self.credentialManager = CredentialManager(logManager: logManager)
        self.preferences = .init()
        self.isUITest = false
        clearDataInKeychainIfFirstRun()
        bindAppState()
        // if ui test reset everything
        if ProcessInfo.processInfo.arguments.contains("RunningInUITests") {
            self.isUITest = true
            self.wipeAllData(includingUnauthSession: true)
        }
        self.apiManager.delegate = self
    }

    private func clearDataInKeychainIfFirstRun() {
        guard preferences.isFirstRun else { return }
        preferences.isFirstRun = false
        sessionData = nil
    }

    private func bindAppState() {
        appStateObserver.$appState
            .receive(on: DispatchQueue.main)
            .dropFirst() // Don't react to default undefined state
            .sink { [weak self] appState in
                guard let self else { return }
                switch appState {
                case .loggedOut(let reason):
                    let shouldWipeUnauthSession = reason != .noAuthSessionButUnauthSessionAvailable
                    self.wipeAllData(includingUnauthSession: shouldWipeUnauthSession)
                    self.showWelcomeScene(reason: reason)

                case let .loggedIn(sessionData, manualLogIn):
                    self.sessionData = sessionData
                    self.apiManager.sessionIsAvailable(authCredential: sessionData.userData.credential,
                                                       scopes: sessionData.userData.scopes)
                    self.showHomeScene(sessionData: sessionData, manualLogIn: manualLogIn)

                case .undefined:
                    self.logger.warning("Undefined app state. Don't know what to do...")
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in
                // Make sure preferences are up to date
                self.preferences = .init()
            }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { _ in
                self.dismissAppLockedViewController()
            }
            .store(in: &cancellables)
    }

    func start() {
        if let sessionData {
            appStateObserver.updateAppState(.loggedIn(data: sessionData, manualLogIn: false))
        } else if unauthSessionCredentials != nil {
            appStateObserver.updateAppState(.loggedOut(.noAuthSessionButUnauthSessionAvailable))
        } else {
            appStateObserver.updateAppState(.loggedOut(.noSessionDataAtAll))
        }
    }

    func getOrCreateSymmetricKey() throws -> SymmetricKey {
        if symmetricKey == nil {
            symmetricKey = String.random(length: 32)
        }

        guard let symmetricKey,
              let symmetricKeyData = symmetricKey.data(using: .utf8) else {
            // Something really nasty is going on 💥
            throw PPError.failedToGetOrCreateSymmetricKey
        }

        return .init(data: symmetricKeyData)
    }

    private func showWelcomeScene(reason: LogOutReason) {
        let welcomeCoordinator = WelcomeCoordinator(apiService: apiManager.apiService)
        welcomeCoordinator.delegate = self
        self.welcomeCoordinator = welcomeCoordinator
        self.homepageCoordinator = nil
        animateUpdateRootViewController(welcomeCoordinator.rootViewController) { [unowned self] in
            switch reason {
            case .expiredRefreshToken:
                self.alertRefreshTokenExpired()
            case .failedBiometricAuthentication:
                self.alertFailedBiometricAuthentication()
            default:
                break
            }
        }
    }

    private func showHomeScene(sessionData: SessionData, manualLogIn: Bool) {
        do {
            let symmetricKey = try getOrCreateSymmetricKey()
            let homepageCoordinator = HomepageCoordinator(apiService: apiManager.apiService,
                                                          container: container,
                                                          credentialManager: credentialManager,
                                                          logManager: logManager,
                                                          manualLogIn: manualLogIn,
                                                          preferences: preferences,
                                                          symmetricKey: symmetricKey,
                                                          userData: sessionData.userData)
            homepageCoordinator.delegate = self
            self.homepageCoordinator = homepageCoordinator
            self.welcomeCoordinator = nil
            animateUpdateRootViewController(homepageCoordinator.rootViewController) {
                homepageCoordinator.onboardIfNecessary()
            }
            if !manualLogIn {
                self.requestBiometricAuthenticationIfNecessary()
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
        sessionData = nil
        if includingUnauthSession {
            apiManager.clearCredentials()
            keymaker.wipeMainKey()
        }
        preferences.reset(isUITests: self.isUITest)
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
            // if their account lacks keys — howeer, after the credentials refresh, the scope is properly set
            apiManager.apiService.refreshCredential(userData.getCredential) { result in
                switch result {
                case .success(let refreshedCredentials) where refreshedCredentials.scopes.contains("pass"):
                    self.apiManager.apiService.setSessionUID(uid: refreshedCredentials.UID)
                    self.apiManager.authHelper.onSessionObtaining(credential: refreshedCredentials)
                    let sessionData = SessionData(userData: userData)
                    self.appStateObserver.updateAppState(.loggedIn(data: sessionData, manualLogIn: true))
                case .success, .failure:
                    self.sessionData = nil
                    self.apiManager.clearCredentials()
                    self.alertNoPassScope()
                }
            }
            return
        }
        let sessionData = SessionData(userData: userData)
        appStateObserver.updateAppState(.loggedIn(data: sessionData, manualLogIn: true))
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
}

// MARK: - APIManagerDelegate
extension AppCoordinator: APIManagerDelegate {
    func appLoggedOut() {
        appStateObserver.updateAppState(.loggedOut(.noSessionDataAtAll))
    }
}

// MARK: - Biometric authentication
private extension AppCoordinator {
    func makeAppLockedViewController() -> UIViewController {
        let view = AppLockedView(
            preferences: preferences,
            logManager: logManager,
            delayed: false,
            onSuccess: { [unowned self] in
                self.dismissAppLockedViewController()
            },
            onFailure: { [unowned self] in
                self.appStateObserver.updateAppState(.loggedOut(.failedBiometricAuthentication))
            })
        let viewController = UIHostingController(rootView: view)
        viewController.modalPresentationStyle = .fullScreen
        return viewController
    }

    func dismissAppLockedViewController() {
        self.appLockedViewController?.dismiss(animated: true)
        self.appLockedViewController = nil
    }

    func requestBiometricAuthenticationIfNecessary() {
        guard preferences.biometricAuthenticationEnabled else { return }
        self.appLockedViewController = self.makeAppLockedViewController()
        guard let appLockedViewController = self.appLockedViewController else { return }
        self.rootViewController?.present(appLockedViewController, animated: false)
    }

    func alertFailedBiometricAuthentication() {
        let alert = UIAlertController(title: "Failed to authenticate",
                                      message: "You have to log in again in order to continue using Proton Pass",
                                      preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        rootViewController?.present(alert, animated: true)
    }
}

// MARK: - HomepageCoordinatorDelegate
extension AppCoordinator: HomepageCoordinatorDelegate {
    func homepageCoordinatorWantsToLogOut() {
        appStateObserver.updateAppState(.loggedOut(.userInitiated))
    }
}
