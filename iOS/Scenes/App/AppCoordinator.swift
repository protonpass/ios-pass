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
import ProtonCore_Authentication
import ProtonCore_Keymaker
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services
import UIComponents
import UIKit

enum AppCoordinatorError: Error {
    case noSessionData
}

final class AppCoordinator {
    private let window: UIWindow
    private let appStateObserver = AppStateObserver()
    private let keymaker: Keymaker
    private let apiService: PMAPIService
    private var container: NSPersistentContainer

    @KeychainStorage(key: "sessionData")
    public private(set) var sessionData: SessionData?

    private var homeCoordinator: HomeCoordinator?
    private var welcomeCoordinator: WelcomeCoordinator?

    private var rootViewController: UIViewController? { window.rootViewController }

    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow) {
        self.window = window
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        self._sessionData.setKeychain(keychain)
        self._sessionData.setMainKeyProvider(keymaker)
        self.keymaker = keymaker
        self.apiService = PMAPIService(doh: PPDoH(bundle: .main))
        self.container = .Builder.build(name: kProtonPassContainerName,
                                        inMemory: false)
        self.apiService.authDelegate = self
        self.apiService.serviceDelegate = self

        bindAppState()
    }

    private func bindAppState() {
        appStateObserver.$appState
            .receive(on: DispatchQueue.main)
            .dropFirst() // Don't react to default undefined state
            .sink { [weak self] appState in
                guard let self = self else { return }
                switch appState {
                case .loggedOut(let refreshTokenExpired):
                    self.wipeAllData()
                    self.showWelcomeScene(refreshTokenExpired: refreshTokenExpired)

                case .loggedIn(let sessionData):
                    self.sessionData = sessionData
                    self.showHomeScene(sessionData: sessionData)

                case .undefined:
                    PPLogger.shared?.log("Undefined app state. Don't know what to do...")
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        if let sessionData = sessionData {
            appStateObserver.updateAppState(.loggedIn(sessionData))
        } else {
            appStateObserver.updateAppState(.loggedOut(refreshTokenExpired: false))
        }
    }

    private func showWelcomeScene(refreshTokenExpired: Bool) {
        let welcomeCoordinator = WelcomeCoordinator(apiServiceDelegate: self)
        welcomeCoordinator.delegate = self
        self.welcomeCoordinator = welcomeCoordinator
        self.homeCoordinator = nil
        animateUpdateRootViewController(welcomeCoordinator.rootViewController) { [unowned self] in
            if refreshTokenExpired {
                self.alertRefreshTokenExpired()
            }
        }
    }

    private func showHomeScene(sessionData: SessionData) {
        let homeCoordinator = HomeCoordinator(sessionData: sessionData,
                                              apiService: apiService,
                                              container: container)
        homeCoordinator.delegate = self
        self.homeCoordinator = homeCoordinator
        self.welcomeCoordinator = nil
        animateUpdateRootViewController(homeCoordinator.rootViewController)
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
        Task {
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
        let alert = PPAlertController(title: "Your session is expired",
                                      message: "Please log in again",
                                      preferredStyle: .alert)
        alert.addAction(.ok)
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
}

// MARK: - WelcomeCoordinatorDelegate
extension AppCoordinator: WelcomeCoordinatorDelegate {
    func welcomeCoordinator(didFinishWith loginData: LoginData) {
        switch loginData {
        case .credential:
            fatalError("Impossible case. Make sure minimumAccountType is set as internal in LoginAndSignUp")
        case .userData(let userData):
            let sessionData = SessionData(userData: userData)
            appStateObserver.updateAppState(.loggedIn(sessionData))
        }
    }
}

// MARK: - HomeCoordinatorDelegate
extension AppCoordinator: HomeCoordinatorDelegate {
    func homeCoordinatorDidSignOut() {
        appStateObserver.updateAppState(.loggedOut(refreshTokenExpired: false))
    }
}

// MARK: - AuthDelegate
extension AppCoordinator: AuthDelegate {
    func getToken(bySessionUID uid: String) -> AuthCredential? { sessionData?.userData.credential }

    func onLogout(sessionUID uid: String) {
        appStateObserver.updateAppState(.loggedOut(refreshTokenExpired: true))
    }

    func onUpdate(auth: Credential) {
        if let sessionData = sessionData {
            updateSessionData(sessionData, credential: auth)
        } else {
            appStateObserver.updateAppState(.loggedOut(refreshTokenExpired: false))
        }
    }

    func onRefresh(bySessionUID uid: String, complete: @escaping AuthRefreshComplete) {
        guard let sessionData = sessionData else {
            PPLogger.shared?.log("Access token expired but found no sessionData in keychain. Logging out...")
            appStateObserver.updateAppState(.loggedOut(refreshTokenExpired: false))
            return
        }
        PPLogger.shared?.log("Refreshing expired access token")
        let authenticator = Authenticator(api: apiService)
        let userData = sessionData.userData
        authenticator.refreshCredential(.init(userData.credential)) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(.updatedCredential(let credential)), .success(.newCredential(let credential, _)):
                PPLogger.shared?.log("Refreshed expired access token")
                self.updateSessionData(sessionData, credential: credential)
                complete(.init(credential), nil)

            case .failure(let error):
                // When falling into this case, it's very likely that refresh token is expired
                // Can't do much here => logging out & displaying an alert
                PPLogger.shared?.log("Error refreshing expired access token: \(error.messageForTheUser)")
                complete(nil, error) // Will trigger onLogout(auth:)

            default:
                PPLogger.shared?.log("Error refreshing expired access token: unexpected response")
                complete(nil, .notImplementedYet("Unexpected response"))  // Will trigger onLogout(auth:)
            }
        }
    }
}

// MARK: - APIServiceDelegate
extension AppCoordinator: APIServiceDelegate {
    var appVersion: String { "iOSPass_\(Bundle.main.versionNumber)" }
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
