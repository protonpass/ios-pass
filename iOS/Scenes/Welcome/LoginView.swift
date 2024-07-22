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

enum LoginViewError: Error {
    case failedExtraPassword(String)
}

struct LoginViewResult {
    let userData: UserData
    let hasExtraPassword: Bool
}

struct LoginView: UIViewControllerRepresentable {
    @Binding private var loginData: Result<LoginViewResult?, LoginViewError>
    private let apiService: any APIService
    private let theme: Theme

    init(apiService: any APIService, theme: Theme, loginData: Binding<Result<LoginViewResult?, LoginViewError>>) {
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

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator

extension LoginView {
    final class Coordinator: @unchecked Sendable, WelcomeViewControllerDelegate {
        weak var viewController: UIViewController?
        private let parent: LoginView
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

        init(_ parent: LoginView) {
            self.parent = parent
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
                    return
                case let .loggedIn(logInData), let .signedUp(logInData):
                    logInAndSignUp = makeLoginAndSignUp()

                    if logInData.scopes.contains(where: { $0 == "pass" }) {
                        parent.loginData = .success(LoginViewResult(userData: logInData, hasExtraPassword: false))
                    } else {
                        Task { @MainActor [weak self] in
                            guard let self else {
                                return
                            }

                            let onSuccess: () -> Void = { [weak self] in
                                guard let self else { return }
                                parent.loginData = .success(LoginViewResult(userData: logInData,
                                                                            hasExtraPassword: true))
                            }

                            let onFailure: () -> Void = { [weak self] in
                                guard let self else { return }
                                parent.loginData = .failure(.failedExtraPassword(logInData.user.ID))

                                DispatchQueue.main.async {
                                    viewController.dismiss(animated: true)
                                }
                            }

                            let username = logInData.credential.userName
            
                            let view = ExtraPasswordLockView(apiService: parent.apiService,
                                                             email: logInData.user.email ?? username,
                                                             username: username,
                                                             onSuccess: onSuccess,
                                                             onFailure: onFailure)
                            let newViewController = UIHostingController(rootView: view)
                            present(rootViewController: viewController, viewController: newViewController)
                        }
                    }
                }
            }
        }

        func userWantsToSignUp() {
            assertionFailure("Should never be called")
        }

        /// When `uniquenessTag` is set and there is a sheet that holds the same tag,
        /// we dismiss the top most sheet and do nothing. Otherwise we present the sheet as normal
        @MainActor
        private func present(rootViewController: UIViewController,
                             viewController: UIViewController,
                             animated: Bool = true,
                             dismissible: Bool = false,
                             delay: TimeInterval = 0.1,
                             uniquenessTag: (any RawRepresentable<Int>)? = nil) {
            viewController.sheetPresentationController?.preferredCornerRadius = 16
            viewController.isModalInPresentation = !dismissible
            if let uniquenessTag {
                viewController.view.tag = uniquenessTag.rawValue
                if rootViewController.containsUniqueSheet(uniquenessTag) {
                    rootViewController.topMostViewController.dismiss(animated: animated)
                    return
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                rootViewController.topMostViewController.present(viewController, animated: true)
            }
        }
    }
}
