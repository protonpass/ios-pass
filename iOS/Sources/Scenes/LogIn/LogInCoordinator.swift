//
// LogInCoordinator.swift
// Proton Key - Created on 21/06/2022.
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
import ProtonCore_LoginUI
import ProtonCore_Networking
import ProtonCore_Services
import SwiftUI
import UIKit

final class LogInCoordinator: Coordinator {
    private let appStateObserver: AppStateObserver
    private let serviceManager = AnonymousServiceManager()

    private lazy var logInController: UIViewController = { .init() }()

    private var forceUpgradeServiceDelegate: ForceUpgradeDelegate {
        // swiftlint:disable:next force_unwrapping
        let url = URL(string: "itms-apps://itunes.apple.com/app/id979659905")!
        return ForceUpgradeHelper(config: .mobile(url), responseDelegate: self)
    }

    init(router: Router,
         navigationType: Coordinator.NavigationType,
         appStateObserver: AppStateObserver) {
        self.appStateObserver = appStateObserver
        super.init(router: router, navigationType: navigationType)
        createLogInPage()
    }

    override var root: Presentable { logInController }

    private func createLogInPage() {
        let login = LoginAndSignup(appName: "Proton Key",
                                   clientApp: .other(named: "Key"),
                                   doh: DohKey(bundle: .main),
                                   apiServiceDelegate: serviceManager,
                                   forceUpgradeDelegate: forceUpgradeServiceDelegate,
                                   humanVerificationVersion: .v3,
                                   minimumAccountType: .external,
                                   isCloseButtonAvailable: true,
                                   paymentsAvailability: .notAvailable,
                                   signupAvailability: .notAvailable)
        login.presentLoginFlow(over: logInController, customization: .empty) { _ in }
    }

    func showHome() {
        appStateObserver.updateState(.loggedIn)
    }
}

public enum BuildConfigKey: String {
    case signUpDomain = "SIGNUP_DOMAIN"
    case captchaHost = "CAPTCHA_HOST"
    case humanVerificationV3Host = "HUMAN_VERIFICATION_V3_HOST"
    case accountHost = "ACCOUNT_HOST"
    case defaultHost = "DEFAULT_HOST"
    case apiHost = "API_HOST"
    case defaultPath = "DEFAULT_PATH"
}

public final class DohKey: DoH, ServerConfig {
    public let signupDomain: String
    public let captchaHost: String
    public let humanVerificationV3Host: String
    public let accountHost: String
    public let defaultHost: String
    public let apiHost: String
    public let defaultPath: String

    public init(bundle: Bundle) {
        let getValue: (BuildConfigKey) -> String = { key in
            if let value = bundle.infoDictionary?[key.rawValue] as? String {
                return value
            }
            fatalError("Key not found \(key.rawValue)")
        }
        self.signupDomain = getValue(.signUpDomain)
        self.captchaHost = getValue(.captchaHost)
        self.humanVerificationV3Host = getValue(.humanVerificationV3Host)
        self.accountHost = getValue(.accountHost)
        self.defaultHost = getValue(.defaultHost)
        self.apiHost = getValue(.apiHost)
        self.defaultPath = getValue(.defaultPath)
    }
}

extension LogInCoordinator: ForceUpgradeResponseDelegate {
    func onQuitButtonPressed() {}
    func onUpdateButtonPressed() {}
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
