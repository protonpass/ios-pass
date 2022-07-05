//
// WelcomeCoordinator.swift
// Proton Key - Created on 02/07/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Key.
//
// Proton Key is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Key is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Key. If not, see https://www.gnu.org/licenses/.

import Client
import Core
import Crypto
import ProtonCore_Doh
import ProtonCore_ForceUpgrade
import ProtonCore_Login
import ProtonCore_LoginUI
import ProtonCore_Networking
import ProtonCore_Services
import UIKit

protocol WelcomeCoordinatorDelegate: AnyObject {
    func welcomeCoordinator(didFinishWith loginData: LoginData)
}

final class WelcomeCoordinator: Coordinator {
    private let apiServiceDelegate: APIServiceDelegate
    private let doh: DoH & ServerConfig
    weak var delegate: WelcomeCoordinatorDelegate?

    private lazy var welcomeViewController: UIViewController = {
        let welcomeScreenTexts = WelcomeScreenTexts(body: "Your next favorite password manager")
        let welcomeScreenVariant = WelcomeScreenVariant.drive(welcomeScreenTexts)
        return WelcomeViewController(variant: welcomeScreenVariant,
                                     delegate: self,
                                     username: nil,
                                     signupAvailable: true)
    }()

    private lazy var forceUpgradeServiceDelegate: ForceUpgradeDelegate = {
        // swiftlint:disable:next force_unwrapping
        let appStoreUrl = URL(string: "itms-apps://itunes.apple.com/app/id979659905")!
        return ForceUpgradeHelper(config: .mobile(appStoreUrl), responseDelegate: self)
    }()

    private lazy var logInAndSignUp: LoginAndSignup = {
        let summaryScreenVariant = SummaryScreenVariant.screenVariant(.drive("Start using Proton Key"))
        let signUpParameters = SignupParameters(passwordRestrictions: .default,
                                                summaryScreenVariant: summaryScreenVariant)
        return .init(appName: "Proton Key",
                     clientApp: .drive,
                     doh: doh,
                     apiServiceDelegate: apiServiceDelegate,
                     forceUpgradeDelegate: forceUpgradeServiceDelegate,
                     humanVerificationVersion: .v3,
                     minimumAccountType: .internal,
                     paymentsAvailability: .notAvailable,
                     signupAvailability: .available(parameters: signUpParameters))
    }()

    override init(router: Router,
                  navigationType: Coordinator.NavigationType) {
        self.apiServiceDelegate = AnonymousServiceManager()
        self.doh = DohKey(bundle: .main)
        super.init(router: router, navigationType: navigationType)
    }

    override var root: Presentable { welcomeViewController }
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
            guard let self = self else { return }
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
            guard let self = self else { return }
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
        delegate?.welcomeCoordinator(didFinishWith: logInData)
    }
}

public class AnonymousServiceManager: APIServiceDelegate {
    public init() {}

    public var locale: String { Locale.autoupdatingCurrent.identifier }
    public var appVersion: String = "iOSPass_1.0.0"
    public var userAgent: String?
    public var additionalHeaders: [String: String]?

    public func onUpdate(serverTime: Int64) { CryptoUpdateTime(serverTime) }
    public func isReachable() -> Bool { true }
    public func onDohTroubleshot() { }
}
