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

final class AppCoordinator {
    private let rootViewController: UIViewController
    private let appStateObserver = AppStateObserver()
    private let sessionStorage: SessionStorage
    private let keymaker: Keymaker

    // Keep a preference to coordinator to make VC presentations work
    private var welcomeCoordinator: WelcomeCoordinator?

    private var cancellables = Set<AnyCancellable>()

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        let keychain = PPKeychain()
        let keymaker = Keymaker(autolocker: Autolocker(lockTimeProvider: keychain), keychain: keychain)
        self.sessionStorage = .init(mainKeyProvider: keymaker, keychain: keychain)
        self.keymaker = keymaker
        bindAppState()
    }

    private func bindAppState() {
        appStateObserver.$appState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appState in
                guard let self = self else { return }
                switch appState {
                case .loggedOut:
                    self.showWelcomeScene()
                case .loggedIn:
                    self.showHomeScene()
                case .undefined:
                    break
                }
            }
            .store(in: &cancellables)
    }

    func start() {
        if sessionStorage.isSignedIn() {
            appStateObserver.updateAppState(.loggedIn)
        } else {
            appStateObserver.updateAppState(.loggedOut)
        }
    }

    private func showWelcomeScene() {
        let presentWelcomeViewController: () -> Void = { [unowned self] in
            let welcomeCoordinator = WelcomeCoordinator()
            welcomeCoordinator.delegate = self
            welcomeCoordinator.welcomeViewController.modalPresentationStyle = .fullScreen
            self.welcomeCoordinator = welcomeCoordinator
            self.rootViewController.present(welcomeCoordinator.welcomeViewController, animated: false)
        }

        if let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.dismiss(animated: true) {
                presentWelcomeViewController()
            }
        } else {
            presentWelcomeViewController()
        }
    }

    private func showHomeScene() {
        let presentSideMenuController: (Bool) -> Void = { [unowned self] animated in
            let homeCoordinator = HomeCoordinator(sessionStorageProvider: self.sessionStorage)
            homeCoordinator.delegate = self
            homeCoordinator.sideMenuController.modalPresentationStyle = .fullScreen
            self.welcomeCoordinator = nil
            self.rootViewController.present(homeCoordinator.sideMenuController, animated: animated)
        }

        if let presentedViewController = rootViewController.presentedViewController {
            presentedViewController.dismiss(animated: true) {
                presentSideMenuController(true)
            }
        } else {
            presentSideMenuController(false)
        }
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
