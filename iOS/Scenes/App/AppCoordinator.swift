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
import Crypto
import CryptoKit
import ProtonCore_Authentication
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import SwiftUI
import UIComponents
import UIKit

enum AppCoordinatorError: Error {
    case noSessionData
    case failedToGetOrCreateSymmetricKey
}

final class AppCoordinator {
    private let window: UIWindow
    private let appStateObserver: AppStateObserver
    private let keymaker: Keymaker
    private let apiService: PMAPIService
    private var container: NSPersistentContainer
    private let credentialManager: CredentialManagerProtocol
    private var preferences: Preferences

    @KeychainStorage(key: .sessionData)
    private var sessionData: SessionData?

    @KeychainStorage(key: .symmetricKey)
    private var symmetricKey: String?

    private var homeCoordinator: HomeCoordinator?
    private var welcomeCoordinator: WelcomeCoordinator?

    private var rootViewController: UIViewController? { window.rootViewController }

    private var appLockedViewController: UIViewController?

    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow) {
        self.window = window
        self.appStateObserver = .init()
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        self._sessionData.setKeychain(keychain)
        self._sessionData.setMainKeyProvider(keymaker)
        self._symmetricKey.setKeychain(keychain)
        self._symmetricKey.setMainKeyProvider(keymaker)
        self.keymaker = keymaker
        self.apiService = PMAPIService(doh: PPDoH(bundle: .main))
        self.container = .Builder.build(name: kProtonPassContainerName,
                                        inMemory: false)
        self.credentialManager = CredentialManager()
        self.preferences = .init()
        self.apiService.authDelegate = self
        self.apiService.serviceDelegate = self

        bindAppState()
    }

    private func bindAppState() {
        appStateObserver.$appState
            .receive(on: DispatchQueue.main)
            .dropFirst() // Don't react to default undefined state
            .sink { [weak self] appState in
                guard let self else { return }
                switch appState {
                case .loggedOut(let reason):
                    self.wipeAllData()
                    self.showWelcomeScene(reason: reason)

                case let .loggedIn(sessionData, manualLogIn):
                    self.sessionData = sessionData
                    self.showHomeScene(sessionData: sessionData, manualLogIn: manualLogIn)

                case .undefined:
                    PPLogger.shared?.log("Undefined app state. Don't know what to do...")
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
        } else {
            appStateObserver.updateAppState(.loggedOut(.noSessionData))
        }
    }

    func getOrCreateSymmetricKey() throws -> SymmetricKey {
        if symmetricKey == nil {
            symmetricKey = String.random(length: 32)
        }

        guard let symmetricKey,
              let symmetricKeyData = symmetricKey.data(using: .utf8) else {
            // Something really nasty is going on 💥
            throw AppCoordinatorError.failedToGetOrCreateSymmetricKey
        }

        return .init(data: symmetricKeyData)
    }

    private func showWelcomeScene(reason: LogOutReason) {
        let welcomeCoordinator = WelcomeCoordinator(apiServiceDelegate: self)
        welcomeCoordinator.delegate = self
        self.welcomeCoordinator = welcomeCoordinator
        self.homeCoordinator = nil
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
            let homeCoordinator = HomeCoordinator(sessionData: sessionData,
                                                  apiService: apiService,
                                                  symmetricKey: symmetricKey,
                                                  container: container,
                                                  credentialManager: credentialManager,
                                                  preferences: preferences)
            homeCoordinator.delegate = self
            self.homeCoordinator = homeCoordinator
            self.welcomeCoordinator = nil
            animateUpdateRootViewController(homeCoordinator.rootViewController)
            if !manualLogIn {
                self.requestBiometricAuthenticationIfNecessary()
            }
            onboardIfNecessary()
        } catch {
            PPLogger.shared?.log(error)
            wipeAllData()
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

    private func wipeAllData() {
        keymaker.wipeMainKey()
        sessionData = nil
        preferences.reset()
        Task {
            // Do things independently in different `do catch` blocks
            // because we don't want a failed operation prevents others from running
            do {
                try await credentialManager.removeAllCredentials()
            } catch {
                PPLogger.shared?.log(error)
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
                PPLogger.shared?.log("Nuked local data")
            } catch {
                PPLogger.shared?.log(error)
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

    // Create a new instance of SessionData with everything copied except credential
    private func updateSessionData(_ sessionData: SessionData,
                                   credential: Credential) {
        let currentUserData = sessionData.userData
        let updatedUserData = UserData(credential: .init(credential),
                                       user: currentUserData.user,
                                       salts: currentUserData.salts,
                                       passphrases: currentUserData.passphrases,
                                       addresses: currentUserData.addresses,
                                       scopes: currentUserData.scopes)
        self.sessionData = .init(userData: updatedUserData)
    }

    private func onboardIfNecessary() {
        guard !preferences.onboarded else { return }
        preferences.onboarded = true
        let onboardingViewModel = OnboardingViewModel(credentialManager: credentialManager,
                                                      preferences: preferences)
        let onboardingView = OnboardingView(viewModel: onboardingViewModel)
        let onboardingViewController = UIHostingController(rootView: onboardingView)
        onboardingViewController.modalPresentationStyle = .fullScreen
        rootViewController?.present(onboardingViewController, animated: true)
    }
}

// MARK: - WelcomeCoordinatorDelegate
extension AppCoordinator: WelcomeCoordinatorDelegate {
    func welcomeCoordinator(didFinishWith loginData: LoginData) {
        switch loginData {
        case .credential:
            fatalError("Impossible case. Make sure minimumAccountType is set as internal in LoginAndSignUp")
        case .userData(let userData):
            guard userData.scopes.contains("pass") else {
                alertNoPassScope()
                return
            }
            let sessionData = SessionData(userData: userData)
            appStateObserver.updateAppState(.loggedIn(data: sessionData, manualLogIn: true))
        }
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

// MARK: - HomeCoordinatorDelegate
extension AppCoordinator: HomeCoordinatorDelegate {
    func homeCoordinatorDidSignOut() {
        appStateObserver.updateAppState(.loggedOut(.userInitiated))
    }

    func homeCoordinatorRequestsBiometricAuthentication() {
        requestBiometricAuthenticationIfNecessary()
    }
}

// MARK: - AuthDelegate
extension AppCoordinator: AuthDelegate {
    func authCredential(sessionUID: String) -> AuthCredential? {
        sessionData?.userData.credential
    }

    func credential(sessionUID: String) -> Credential? {
        nil
    }

    func getToken(bySessionUID uid: String) -> AuthCredential? { sessionData?.userData.credential }

    func onLogout(sessionUID uid: String) {
        appStateObserver.updateAppState(.loggedOut(.expiredRefreshToken))
    }

    func onUpdate(credential auth: Credential, sessionUID: String) {
        if let sessionData {
            updateSessionData(sessionData, credential: auth)
        } else {
            appStateObserver.updateAppState(.loggedOut(.noSessionData))
        }
    }

    func onRefresh(sessionUID: String,
                   service: APIService,
                   complete: @escaping AuthRefreshResultCompletion) {
        guard let sessionData else {
            PPLogger.shared?.log("Access token expired but found no sessionData in keychain. Logging out...")
            appStateObserver.updateAppState(.loggedOut(.noSessionData))
            return
        }
        PPLogger.shared?.log("Refreshing expired access token")
        let authenticator = Authenticator(api: apiService)
        let userData = sessionData.userData
        authenticator.refreshCredential(.init(userData.credential)) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(.updatedCredential(let credential)), .success(.newCredential(let credential, _)):
                PPLogger.shared?.log("Refreshed expired access token")
                self.updateSessionData(sessionData, credential: credential)
                complete(.success(.init(.init(credential))))

            case .failure(let error):
                // When falling into this case, it's very likely that refresh token is expired
                // Can't do much here => logging out & displaying an alert
                PPLogger.shared?.log("Error refreshing expired access token: \(error.messageForTheUser)")
                complete(.failure(error)) // Will trigger onLogout(auth:)

            default:
                PPLogger.shared?.log("Error refreshing expired access token: unexpected response")
                complete(.failure(.emptyAuthResponse))  // Will trigger onLogout(auth:)
            }
        }
    }
}

// MARK: - APIServiceDelegate
extension AppCoordinator: APIServiceDelegate {
    var appVersion: String { "ios-pass@\(Bundle.main.fullAppVersionName())" }
    var userAgent: String? { UserAgent.default.ua }
    var locale: String { Locale.autoupdatingCurrent.identifier }
    var additionalHeaders: [String: String]? { nil }

    func onDohTroubleshot() {}

    func onUpdate(serverTime: Int64) {
        CryptoUpdateTime(serverTime)
    }

    func isReachable() -> Bool {
        // swiftlint:disable:next todo
        // TODO: Handle this
        return true
    }
}

// MARK: - Biometric authentication
private extension AppCoordinator {
    func makeAppLockedViewController() -> UIViewController {
        let view = AppLockedView(
            preferences: preferences,
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
