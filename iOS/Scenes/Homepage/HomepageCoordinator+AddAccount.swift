//
// HomepageCoordinator+AddAccount.swift
// Proton Pass - Created on 23/07/2024.
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

import Foundation
import Macro
import ProtonCoreLogin
import ProtonCoreLoginUI
import ProtonCoreServices
import SwiftUI

extension HomepageCoordinator {
    func beginAddAccountFlow() {
        let options = LoginCustomizationOptions(inAppTheme: { [weak self] in
            guard let self else { return .default }
            return getSharedPreferences().theme.inAppTheme
        })
        logInAndSignUp.presentLoginFlow(over: rootViewController,
                                        customization: options,
                                        completion: { [weak self] result in
                                            guard let self else { return }
                                            handle(result)
                                        })
    }

    func makeLoginAndSignUp() -> LoginAndSignup {
        let params = SignupParameters(separateDomainsButton: true,
                                      passwordRestrictions: .default,
                                      summaryScreenVariant: .noSummaryScreen)
        return .init(appName: "Proton Pass",
                     clientApp: .pass,
                     apiService: apiManager.getUnauthApiService(),
                     minimumAccountType: .external,
                     paymentsAvailability: .notAvailable,
                     signupAvailability: .available(parameters: params))
    }
}

private extension HomepageCoordinator {
    func handle(_ result: LoginResult) {
        switch result {
        case .dismissed:
            return
        case let .loggedIn(logInData), let .signedUp(logInData):
            logInAndSignUp = makeLoginAndSignUp()

            if logInData.scopes.contains(where: { $0 == "pass" }) {
                finalizeAddingAccount(userData: logInData, hasExtraPassword: false)
            } else {
                let onSuccess: () -> Void = { [weak self] in
                    guard let self else { return }
                    rootViewController.dismiss(animated: true) { [weak self] in
                        guard let self else { return }
                        finalizeAddingAccount(userData: logInData, hasExtraPassword: true)
                    }
                }

                let onFailure: () -> Void = { [weak self] in
                    guard let self else { return }
                    rootViewController.dismiss(animated: true)
                }

                let username = logInData.credential.userName
                let view = ExtraPasswordLockView(apiServicing: apiManager,
                                                 email: logInData.user.email ?? username,
                                                 username: username,
                                                 userId: logInData.user.ID,
                                                 onSuccess: onSuccess,
                                                 onFailure: onFailure)
                present(view, dismissible: false)
            }
        }
    }

    func finalizeAddingAccount(userData: UserData, hasExtraPassword: Bool) {
        Task { [weak self] in
            guard let self else { return }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                guard try await canAddNewAccount(userId: userData.user.ID) else {
                    router.display(element: .globalLoading(shouldShow: false))
                    let message = #localized("Only one free Proton Pass account is allowed")
                    bannerManager.displayTopErrorMessage(message)
                    authManager.removeCredentials(userId: userData.user.ID)
                    return
                }
                router.display(element: .globalLoading(shouldShow: false))

                router.present(for: .fullSync)
                logger.info("Doing full sync")
                try await addAndSwitchToNewUserAccount(userData: userData,
                                                       hasExtraPassword: hasExtraPassword)
                logger.info("Done full sync")
                router.display(element: .successMessage(config: .refresh))
            } catch {
                handle(error: error)
            }
        }
    }
}
