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

import Combine
import Core
import ProtonCore_Keymaker
import ProtonCore_Login
import UIKit

final class AppCoordinator: Coordinator {
    private let appStateObserver: AppStateObserver
    private let sessionStorage: SessionStorage
    private let keymaker: Keymaker

    override var root: Presentable { router.toPresentable() }

    init(appStateObserver: AppStateObserver,
         router: Router) {
        self.appStateObserver = appStateObserver
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        self.sessionStorage = .init(mainKeyProvider: keymaker, keychain: keychain)
        self.keymaker = keymaker
        super.init(router: router, navigationType: .newFlow(hideBar: true))

        bindAppState()
        bindDeeplink()

        if sessionStorage.isSignedIn() {
            appStateObserver.updateAppState(.loggedIn)
        }
    }

    private func bindAppState() {
        appStateObserver.$appState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appState in
                guard let self = self else { return }
                switch appState {
                case .loggedOut:
                    self.setUpWelcomeFlow()
                case .loggedIn:
                    self.setUpHomeFlow()
                }
            }
            .store(in: &cancellables)
    }

    private func bindDeeplink() {
        deeplinkSubject
            .unwrap()
            .map(AppFlow.init(deeplink:))
            .unwrap()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deeplink in
                guard let self = self else { return }
                switch deeplink {
                case .welcome:
                    self.setUpWelcomeFlow()
                case .home:
                    self.setUpHomeFlow()
                }
                self.resetDeeplink()
            }.store(in: &cancellables)
    }

    private func setUpWelcomeFlow() {
        let welcomeCoordinator = WelcomeCoordinator(router: router,
                                                    navigationType: .newFlow(hideBar: true))
        welcomeCoordinator.delegate = self
        setRootChild(coordinator: welcomeCoordinator, hideBar: true)
    }

    private func setUpHomeFlow() {
        let homeCoordinator = HomeCoordinator(router: router,
                                              navigationType: .newFlow(hideBar: true),
                                              sessionStorageProvider: sessionStorage)
        homeCoordinator.delegate = self
        setRootChild(coordinator: homeCoordinator, hideBar: true)
    }

    private func signOut() {
        sessionStorage.signOut()
        appStateObserver.updateAppState(.loggedOut)
    }
}

// MARK: - WelcomeCoordinatorDelegate
extension AppCoordinator: WelcomeCoordinatorDelegate {
    func welcomeCoordinator(didFinishWith loginData: LoginData) {
        switch loginData {
        case .credential:
            fatalError("Impossible case. Make sure minimumAccountType is set as internal in LoginAndSignUp")
        case .userData(let userData):
            sessionStorage.bind(userData: userData)
            appStateObserver.updateAppState(.loggedIn)
        }
    }
}

// MARK: - HomeCoordinatorDelegate
extension AppCoordinator: HomeCoordinatorDelegate {
    func homeCoordinatorDidSignOut() {
        signOut()
    }
}
