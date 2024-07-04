//
// LoginView.swift
// Proton Pass - Created on 03/07/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities
import Macro
import ProtonCoreLogin
import ProtonCoreLoginUI
import ProtonCoreServices
import SwiftUI

struct LoginView: UIViewControllerRepresentable {
    @Binding private var loginData: LoginData?
    private let apiService: any APIService
    private let theme: Theme

    init(apiService: any APIService, theme: Theme, loginData: Binding<LoginData?>) {
        self.apiService = apiService
        self.theme = theme
        _loginData = loginData
    }

    func makeUIViewController(context: Context) -> WelcomeViewController {
        let welcomeViewController =
            WelcomeViewController(variant: .pass(.init(body: #localized("Secure password manager and more"))),
                                  delegate: context.coordinator,
                                  username: nil,
                                  signupAvailable: false)
        context.coordinator.viewController = welcomeViewController
        return welcomeViewController
    }

    func updateUIViewController(_ uiViewController: WelcomeViewController, context: Context) {}

    class Coordinator: WelcomeViewControllerDelegate {
        weak var viewController: UIViewController?
        private let parent: LoginView

        init(_ parent: LoginView) {
            self.parent = parent
        }

        private lazy var logInAndSignUp = makeLoginAndSignUp()

        private func makeLoginAndSignUp() -> LoginAndSignup {
            .init(appName: "Proton Pass",
                  clientApp: .pass,
                  apiService: parent.apiService,
                  minimumAccountType: .external,
                  paymentsAvailability: .notAvailable,
                  signupAvailability: .notAvailable)
        }

        private var customization: LoginCustomizationOptions {
            LoginCustomizationOptions(inAppTheme: { [weak self] in
                guard let self else { return .default }
                return parent.theme.inAppTheme
            })
        }

        func userWantsToLogIn(username: String?) {
            guard let viewController else {
                return
            }
            logInAndSignUp.presentLoginFlow(over: viewController,
                                            customization: customization) { [weak self] result in
                guard let self else { return }
                switch result {
                case .dismissed:
                    DispatchQueue.main.async {
                        viewController.dismiss(animated: false)
                    }
                case let .loggedIn(logInData), let .signedUp(logInData):
                    logInAndSignUp = makeLoginAndSignUp()

                    // TODO: IF scope is not full user has extra password need to take that into  account
                    parent.loginData = logInData
                }
            }
        }

        func userWantsToSignUp() {
            guard let viewController else {
                return
            }

            logInAndSignUp.presentSignupFlow(over: viewController,
                                             customization: customization) { [weak self] result in
                guard let self else { return }
                switch result {
                case .dismissed:
                    DispatchQueue.main.async {
                        viewController.dismiss(animated: false)
                    }
                case let .loggedIn(logInData), let .signedUp(logInData):
                    logInAndSignUp = makeLoginAndSignUp()
                    parent.loginData = logInData
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
