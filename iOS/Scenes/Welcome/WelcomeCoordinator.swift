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

import Core
import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreLogin
import ProtonCoreLoginUI
import ProtonCoreNetworking
import ProtonCoreServices
import Screens
import SwiftUI
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

    private let apiService: any APIService
    private let theme: Theme

    weak var delegate: (any WelcomeCoordinatorDelegate)?
    var rootViewController: UIViewController { welcomeViewController }

    @LazyInjected(\UseCasesContainer.createLogsFile) private var createLogsFile
    @LazyInjected(\SharedRepositoryContainer.featureFlagsRepository) private var featureFlagsRepository
    let getSharedPreferences = resolve(\SharedUseCasesContainer.getSharedPreferences)

    init(apiService: any APIService, theme: Theme) {
        self.apiService = apiService
        self.theme = theme
        featureFlagsRepository.clearUserId()
    }
}

private extension WelcomeCoordinator {
    func makeWelcomeViewController() -> UIViewController {
        // TODO: implement a/b testing for the login
        let welcomeViewController = UIHostingController(rootView: LoginOnboardingView(onAction: { [weak self] in
            guard let self else { return }
            beginAddAccountFlow()
        }))
//            WelcomeViewController(variant: .pass(.init(body: #localized("Secure password manager and more"))),
//                                  delegate: self,
//                                  username: nil,
//                                  signupAvailable: true)
        welcomeViewController.view?.addShakeMotionDetector { [weak self] in
            guard let self else { return }
            presentReportBugsAlert()
        }
        return welcomeViewController
    }

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

    @objc
    func presentReportBugsAlert() {
        let alert = UIAlertController(title: #localized("Report a problem"),
                                      message: nil,
                                      preferredStyle: UIDevice.current.isIpad ? .alert : .actionSheet)
        alert.addAction(.init(title: #localized("Send logs"),
                              style: .default,
                              handler: { [weak self] _ in
                                  guard let self else { return }
                                  shareLogs()
                              }))

        alert.addAction(.init(title: #localized("Cancel"), style: .cancel))
        rootViewController.present(alert, animated: true)
    }

    func alert(_ error: any Error) {
        let alert = UIAlertController(title: #localized("Error occurred"),
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: #localized("Cancel"), style: .cancel))
        rootViewController.present(alert, animated: true)
    }

    func shareLogs() {
        Task { [weak self] in
            guard let self else { return }
            do {
                async let getGostAppLogs = try createLogsFile(for: PassModule.hostApp)
                async let getAutofillLogs = try createLogsFile(for: PassModule.autoFillExtension)
                let (hostAppLogs, autofillLogs) = try await (getGostAppLogs, getAutofillLogs)
                let urls = [hostAppLogs, autofillLogs].compactMap { $0 }

                guard !urls.isEmpty else { return }
                let activityController = UIActivityViewController(activityItems: urls, applicationActivities: nil)

                if UIDevice.current.isIpad,
                   let popoverController = activityController.popoverPresentationController,
                   let sourceView = rootViewController.view {
                    popoverController.sourceView = sourceView
                    popoverController.sourceRect = CGRect(x: sourceView.bounds.midX,
                                                          y: sourceView.bounds.midY,
                                                          width: 0,
                                                          height: 0)
                    popoverController.permittedArrowDirections = []
                }
                rootViewController.present(activityController, animated: true)
            } catch {
                alert(error)
            }
        }
    }

    func makeLoginAndSignUp() -> LoginAndSignup {
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

    func oldLoginFlow() -> UIViewController {
        WelcomeViewController(variant: .pass(.init(body: #localized("Secure password manager and more"))),
                              delegate: self,
                              username: nil,
                              signupAvailable: true)
    }
}

// MARK: - WelcomeViewControllerDelegate

extension WelcomeCoordinator: WelcomeViewControllerDelegate {
    nonisolated func userWantsToLogIn(username: String?) {
        let customization: LoginCustomizationOptions = .init(inAppTheme: { [weak self] in
            guard let self else { return .default }
            return theme.inAppTheme
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
            return theme.inAppTheme
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

    func handle(_ result: LoginResult) {
        switch result {
        case .dismissed:
            return
        case let .loggedIn(logInData), let .signedUp(logInData):
            logInAndSignUp = makeLoginAndSignUp()

//            if logInData.scopes.contains(where: { $0 == "pass" }) {
            handle(logInData: logInData)
//            }
//            else {
//                let onSuccess: () -> Void = { [weak self] in
//                    guard let self else { return }
//                    rootViewController.dismiss(animated: true) { [weak self] in
//                        guard let self else { return }
//                        handle(logInData: logInData)
            ////                        finalizeAddingAccount(userData: logInData, hasExtraPassword: true)
//                    }
//                }
//
//                let onFailure: () -> Void = { [weak self] in
//                    guard let self else { return }
//                    rootViewController.dismiss(animated: true)
//                }
//
//                let username = logInData.credential.userName
//                let view = ExtraPasswordLockView(apiServicing: apiManager,
//                                                 email: logInData.user.email ?? username,
//                                                 username: username,
//                                                 userId: logInData.user.ID,
//                                                 onSuccess: onSuccess,
//                                                 onFailure: onFailure)
//                present(view, dismissible: false)
//            }
        }
    }
}

//
// import Foundation
// import Macro
// import ProtonCoreLogin
// import ProtonCoreLoginUI
// import ProtonCoreServices
// import SwiftUI
//
// extension HomepageCoordinator {
//    func beginAddAccountFlow() {
//        let options = LoginCustomizationOptions(inAppTheme: { [weak self] in
//            guard let self else { return .default }
//            return getSharedPreferences().theme.inAppTheme
//        })
//        logInAndSignUp.presentLoginFlow(over: rootViewController,
//                                        customization: options,
//                                        completion: { [weak self] result in
//                                            guard let self else { return }
//                                            handle(result)
//                                        })
//    }
//
//    func makeLoginAndSignUp() -> LoginAndSignup {
//        let params = SignupParameters(separateDomainsButton: true,
//                                      passwordRestrictions: .default,
//                                      summaryScreenVariant: .noSummaryScreen)
//        return .init(appName: "Proton Pass",
//                     clientApp: .pass,
//                     apiService: apiManager.getUnauthApiService(),
//                     minimumAccountType: .external,
//                     paymentsAvailability: .notAvailable,
//                     signupAvailability: .available(parameters: params))
//    }
// }
//
// private extension HomepageCoordinator {
//    func handle(_ result: LoginResult) {
//        switch result {
//        case .dismissed:
//            return
//        case let .loggedIn(logInData), let .signedUp(logInData):
//            logInAndSignUp = makeLoginAndSignUp()
//
//            if logInData.scopes.contains(where: { $0 == "pass" }) {
//                finalizeAddingAccount(userData: logInData, hasExtraPassword: false)
//            } else {
//                let onSuccess: () -> Void = { [weak self] in
//                    guard let self else { return }
//                    rootViewController.dismiss(animated: true) { [weak self] in
//                        guard let self else { return }
//                        finalizeAddingAccount(userData: logInData, hasExtraPassword: true)
//                    }
//                }
//
//                let onFailure: () -> Void = { [weak self] in
//                    guard let self else { return }
//                    rootViewController.dismiss(animated: true)
//                }
//
//                let username = logInData.credential.userName
//                let view = ExtraPasswordLockView(apiServicing: apiManager,
//                                                 email: logInData.user.email ?? username,
//                                                 username: username,
//                                                 userId: logInData.user.ID,
//                                                 onSuccess: onSuccess,
//                                                 onFailure: onFailure)
//                present(view, dismissible: false)
//            }
//        }
//    }
//
//    func finalizeAddingAccount(userData: UserData, hasExtraPassword: Bool) {
//        Task { [weak self] in
//            guard let self else { return }
//            do {
//                router.display(element: .globalLoading(shouldShow: true))
//                guard try await canAddNewAccount(userId: userData.user.ID) else {
//                    router.display(element: .globalLoading(shouldShow: false))
//                    let message = #localized("Only one free Proton Pass account is allowed")
//                    bannerManager.displayTopErrorMessage(message)
//                    authManager.removeCredentials(userId: userData.user.ID)
//                    return
//                }
//                router.display(element: .globalLoading(shouldShow: false))
//
//                addTelemetryEvent(with: .multiAccountAddAccount)
//
//                router.present(for: .fullSync)
//                logger.info("Doing full sync")
//                try await addAndSwitchToNewUserAccount(userData: userData,
//                                                       hasExtraPassword: hasExtraPassword)
//                logger.info("Done full sync")
//                router.display(element: .successMessage(config: .refresh))
//            } catch {
//                handle(error: error)
//            }
//        }
//    }
// }
