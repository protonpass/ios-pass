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
import Entities
import FactoryKit
import Macro
import ProtonCoreLogin
import ProtonCoreLoginUI
import ProtonCoreNetworking
import ProtonCoreServices
import Screens
import SwiftUI

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
        let view = LoginOnboardingView(onAction: { [weak self] signUp in
            guard let self else { return }
            beginAddAccountFlow(isSigningUp: signUp)
        })

        let welcomeViewController = UIHostingController(rootView: view)

        welcomeViewController.view?.addShakeMotionDetector { [weak self] in
            guard let self else { return }
            presentReportBugsAlert()
        }
        return welcomeViewController
    }

    func beginAddAccountFlow(isSigningUp: Bool) {
        let options = LoginCustomizationOptions(inAppTheme: { [weak self] in
            guard let self else { return .default }
            return getSharedPreferences().theme.inAppTheme
        })
        if isSigningUp {
            logInAndSignUp.presentSignupFlow(over: rootViewController,
                                             customization: options) { [weak self] result in
                guard let self else { return }
                handle(result)
            }
        } else {
            logInAndSignUp.presentLoginFlow(over: rootViewController,
                                            customization: options) { [weak self] result in
                guard let self else { return }
                handle(result)
            }
        }
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
                async let getHostAppLogs = try createLogsFile(for: PassModule.hostApp)
                async let getAutofillLogs = try createLogsFile(for: PassModule.autoFillExtension)
                let (hostAppLogs, autofillLogs) = try await (getHostAppLogs, getAutofillLogs)
                let urls = [hostAppLogs, autofillLogs].compactMap(\.self)

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
}

private extension WelcomeCoordinator {
    func handle(logInData: LoginData) {
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
            handle(logInData: logInData)
        }
    }
}
