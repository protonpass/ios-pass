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
import GoLibs
import ProtonCore_Doh
import ProtonCore_ForceUpgrade
import ProtonCore_Login
import ProtonCore_LoginUI
import ProtonCore_Networking
import ProtonCore_Services
import UIComponents
import UIKit

protocol WelcomeCoordinatorDelegate: AnyObject {
    func welcomeCoordinator(didFinishWith loginData: LoginData)
}

final class WelcomeCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    private lazy var welcomeViewController = makeWelcomeViewController()
    private lazy var logInAndSignUp = makeLoginAndSignUp()

    private let apiService: APIService

    weak var delegate: WelcomeCoordinatorDelegate?
    var rootViewController: UIViewController { welcomeViewController }

    init(apiService: APIService) {
        self.apiService = apiService
    }

    private func makeWelcomeViewController() -> UIViewController {
        let welcomeScreenVariant = WelcomeScreenVariant.custom(
            .init(topImage: PassIcon.swirls,
                  logo: PassIcon.passIcon,
                  wordmark: PassIcon.passTextLogo,
                  body: "Secure password manager and more",
                  brand: .proton))
        return WelcomeViewController(variant: welcomeScreenVariant,
                                     delegate: self,
                                     username: nil,
                                     signupAvailable: true)
    }

    private func makeForceUpgradeDelegate() -> ForceUpgradeDelegate {
        // swiftlint:disable:next force_unwrapping
        let appStoreUrl = URL(string: "itms-apps://itunes.apple.com/app/id6443490629")!
        return ForceUpgradeHelper(config: .mobile(appStoreUrl), responseDelegate: self)
    }

    private func makeLoginAndSignUp() -> LoginAndSignup {
        let signUpParameters = SignupParameters(separateDomainsButton: true,
                                                passwordRestrictions: .default,
                                                summaryScreenVariant: .noSummaryScreen,
                                                signupInitialMode: .internal)
        return .init(appName: "Proton Pass",
                     clientApp: .other(named: "pass"),
                     apiService: apiService,
                     minimumAccountType: .external,
                     paymentsAvailability: .notAvailable,
                     signupAvailability: .available(parameters: signUpParameters))
    }
}

// MARK: - ForceUpgradeResponseDelegate
extension WelcomeCoordinator: ForceUpgradeResponseDelegate {
    func onQuitButtonPressed() {}
    func onUpdateButtonPressed() {}
}

// MARK: - WelcomeViewControllerDelegate
extension WelcomeCoordinator: WelcomeViewControllerDelegate {
    func userWantsToLogIn(username: String?) {
        logInAndSignUp.presentLoginFlow(over: welcomeViewController) { [weak self] result in
            guard let self else { return }
            switch result {
            case .dismissed:
                break
            case .loggedIn(let logInData):
                self.handle(logInData: logInData)
            case .signedUp(let logInData):
                self.handle(logInData: logInData)
            }
        }
    }

    func userWantsToSignUp() {
        logInAndSignUp.presentSignupFlow(over: welcomeViewController) { [weak self] result in
            guard let self else { return }
            switch result {
            case .dismissed:
                break
            case .loggedIn(let logInData):
                self.handle(logInData: logInData)
            case .signedUp(let logInData):
                self.handle(logInData: logInData)
            }
        }
    }

    private func handle(logInData: LoginData) {
        // Have to refresh `logInAndSignUp` in case `logInData` is ignored and user has to authenticate again.
        logInAndSignUp = makeLoginAndSignUp()
        delegate?.welcomeCoordinator(didFinishWith: logInData)
    }
}
