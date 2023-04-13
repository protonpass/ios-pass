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
    private let appVersion = "ios-pass@\(Bundle.main.fullAppVersionName())"

    private var homepageCoordinator: HomepageCoordinator?
    private var welcomeCoordinator: WelcomeCoordinator?

    private var rootViewController: UIViewController? { window.rootViewController }

    private var appLockedViewController: UIViewController?

    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow) {
        self.window = window
        self.appStateObserver = .init()
        let logManager = LogManager(module: .hostApp)
        self.logManager = logManager
        self.logger = .init(manager: logManager)
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        let appData = AppData(keychain: keychain, mainKeyProvider: keymaker, logManager: logManager)
        self.appData = appData
        self.keymaker = keymaker
        self.apiManager = APIManager(logManager: logManager, appVer: appVersion, appData: appData)
        self.container = .Builder.build(name: kProtonPassContainerName,
                                        inMemory: false)
        self.credentialManager = CredentialManager(logManager: logManager)
        self.preferences = .init()
        self.isUITest = false
        clearUserDataInKeychainIfFirstRun()
        bindAppState()
        refreshPrimaryPlan()
        // if ui test reset everything
        if ProcessInfo.processInfo.arguments.contains("RunningInUITests") {
            self.isUITest = true
            self.wipeAllData(includingUnauthSession: true)
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
                case .loggedOut(let reason):
                    let shouldWipeUnauthSession = reason != .noAuthSessionButUnauthSessionAvailable
                    self.wipeAllData(includingUnauthSession: shouldWipeUnauthSession)
                    self.showWelcomeScene(reason: reason)

                case let .loggedIn(userData, manualLogIn):
                    self.appData.userData = userData
                    self.apiManager.sessionIsAvailable(authCredential: userData.credential,
                                                       scopes: userData.scopes)
                    self.showHomeScene(userData: userData, manualLogIn: manualLogIn)

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

                // Request biometric authentication if user is logged in
                if self.homepageCoordinator != nil {
                    self.requestBiometricAuthenticationIfNecessary()
                }
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

    private func showHomeScene(userData: UserData, manualLogIn: Bool) {
        Task { @MainActor in
            do {
                let apiService = apiManager.apiService
                if manualLogIn {
                    showLoadingHud()
                    appData.primaryPlan =
                    try? await PrimaryPlanProvider.getPrimaryPlan(apiService: apiService)
                    hideLoadingHud()
                }
                let symmetricKey = try appData.getSymmetricKey()
                let homepageCoordinator = HomepageCoordinator(apiService: apiService,
                                                              container: container,
                                                              credentialManager: credentialManager,
                                                              logManager: logManager,
                                                              manualLogIn: manualLogIn,
                                                              preferences: preferences,
                                                              primaryPlan: appData.primaryPlan,
                                                              symmetricKey: symmetricKey,
                                                              userData: userData)
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
        appData.primaryPlan = nil
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

    private func refreshPrimaryPlan() {
        Task {
            do {
                logger.trace("Refreshing primary plan")
                appData.primaryPlan =
                try await PrimaryPlanProvider.getPrimaryPlan(apiService: apiManager.apiService)
                logger.trace("Refreshed primary plan")
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
                case .success(let refreshedCredentials) where refreshedCredentials.scopes.contains("pass"):
                    self.apiManager.apiService.setSessionUID(uid: refreshedCredentials.UID)
                    self.apiManager.authHelper.onSessionObtaining(credential: refreshedCredentials)
                    self.appStateObserver.updateAppState(.loggedIn(userData: userData, manualLogIn: true))
                case .success, .failure:
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
