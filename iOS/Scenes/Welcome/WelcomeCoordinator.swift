//
// WelcomeCoordinator.swift
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
import Core
import DesignSystem
import Macro
import ProtonCoreDoh
import ProtonCoreForceUpgrade
import ProtonCoreLogin
import ProtonCoreLoginUI
import ProtonCoreNetworking
import ProtonCoreServices
import UIKit

@MainActor
protocol WelcomeCoordinatorDelegate: AnyObject {
    func welcomeCoordinator(didFinishWith loginData: LoginData)
}

@MainActor
final class WelcomeCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    private lazy var welcomeViewController = makeWelcomeViewController()
    private lazy var logInAndSignUp = makeLoginAndSignUp()

    private let apiService: APIService
    private let preferences: Preferences

    weak var delegate: WelcomeCoordinatorDelegate?
    var rootViewController: UIViewController { welcomeViewController }

    init(apiService: APIService, preferences: Preferences) {
        self.apiService = apiService
        self.preferences = preferences
    }

    private func makeWelcomeViewController() -> UIViewController {
        let welcomeViewController =
            WelcomeViewController(variant: .pass(.init(body: #localized("Secure password manager and more"))),
                                  delegate: self,
                                  username: nil,
                                  signupAvailable: true)
        welcomeViewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
        return welcomeViewController
    }

    private func makeLoginAndSignUp() -> LoginAndSignup {
        let signUpParameters = SignupParameters(separateDomainsButton: true,
                                                passwordRestrictions: .default,
                                                summaryScreenVariant: .noSummaryScreen)
        return .init(appName: "Proton Pass",
                     clientApp: .pass,
                     apiService: apiService,
                     minimumAccountType: .external,
                     paymentsAvailability: .notAvailable,
                     signupAvailability: .available(parameters: signUpParameters))
    }
}

// MARK: - WelcomeViewControllerDelegate

extension LoginCustomizationOptions: @unchecked Sendable {}

extension WelcomeCoordinator: WelcomeViewControllerDelegate {
    nonisolated func userWantsToLogIn(username: String?) {
        let customization: LoginCustomizationOptions = .init(inAppTheme: { [weak self] in
            guard let self else { return .default }
            return preferences.theme.inAppTheme
        })
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            logInAndSignUp.presentLoginFlow(over: welcomeViewController,
                                            customization: customization) { [weak self] result in
                guard let self else { return }
                switch result {
                case .dismissed:
                    break
                case let .loggedIn(logInData):
                    handle(logInData: logInData)
                case let .signedUp(logInData):
                    handle(logInData: logInData)
                }
            }
        }
    }

    nonisolated func userWantsToSignUp() {
        let customization: LoginCustomizationOptions = .init(inAppTheme: { [weak self] in
            guard let self else { return .default }
            return preferences.theme.inAppTheme
        })
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            logInAndSignUp.presentSignupFlow(over: welcomeViewController,
                                             customization: customization) { [weak self] result in
                guard let self else { return }
                switch result {
                case .dismissed:
                    break
                case let .loggedIn(logInData):
                    handle(logInData: logInData)
                case let .signedUp(logInData):
                    handle(logInData: logInData)
                }
            }
        }
    }

    private func handle(logInData: LoginData) {
        // Have to refresh `logInAndSignUp` in case `logInData` is ignored and user has to authenticate again.
        logInAndSignUp = makeLoginAndSignUp()
        delegate?.welcomeCoordinator(didFinishWith: logInData)
    }
}
