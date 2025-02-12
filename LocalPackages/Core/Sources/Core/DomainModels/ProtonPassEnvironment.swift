//
// ProtonPassEnvironment.swift
// Proton Pass - Created on 29/05/2023.
// Copyright (c) 2023 Proton Technologies AG
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

public enum ProtonPassEnvironment: Sendable {
    case black, prod, scientist(String), custom(DoHParameters)

    public var parameters: DoHParameters {
        switch self {
        case .black:
            return .init(signupDomain: Bundle.main.plistString(for: .signupDomain, in: .black),
                         captchaHost: Bundle.main.plistString(for: .captchaHost, in: .black),
                         humanVerificationV3Host: Bundle.main.plistString(for: .humanVerificationHost, in: .black),
                         accountHost: Bundle.main.plistString(for: .accountHost, in: .black),
                         defaultHost: Bundle.main.plistString(for: .defaultHost, in: .black),
                         apiHost: Bundle.main.plistString(for: .apiHost, in: .black),
                         defaultPath: Bundle.main.plistString(for: .defaultPath, in: .black))

        case .prod:
            return .init(signupDomain: Bundle.main.plistString(for: .signupDomain, in: .prod),
                         captchaHost: Bundle.main.plistString(for: .captchaHost, in: .prod),
                         humanVerificationV3Host: Bundle.main.plistString(for: .humanVerificationHost, in: .prod),
                         accountHost: Bundle.main.plistString(for: .accountHost, in: .prod),
                         defaultHost: Bundle.main.plistString(for: .defaultHost, in: .prod),
                         apiHost: Bundle.main.plistString(for: .apiHost, in: .prod),
                         defaultPath: Bundle.main.plistString(for: .defaultPath, in: .prod))

        case let .scientist(name):
            let placeholder = "<ENV_NAME>"
            let signUpDomain = Bundle.main.plistString(for: .signupDomain, in: .scientist)
            let captchaHost = Bundle.main.plistString(for: .captchaHost, in: .scientist)
            let hvHost = Bundle.main.plistString(for: .humanVerificationHost, in: .scientist)
            let accountHost = Bundle.main.plistString(for: .accountHost, in: .scientist)
            let defaultHost = Bundle.main.plistString(for: .defaultHost, in: .scientist)
            let apiHost = Bundle.main.plistString(for: .apiHost, in: .scientist)
            let defaultPath = Bundle.main.plistString(for: .defaultPath, in: .scientist)
            return .init(signupDomain: signUpDomain.replacingOccurrences(of: placeholder, with: name),
                         captchaHost: captchaHost.replacingOccurrences(of: placeholder, with: name),
                         humanVerificationV3Host: hvHost.replacingOccurrences(of: placeholder,
                                                                              with: name),
                         accountHost: accountHost.replacingOccurrences(of: placeholder, with: name),
                         defaultHost: defaultHost.replacingOccurrences(of: placeholder, with: name),
                         apiHost: apiHost.replacingOccurrences(of: placeholder, with: name),
                         defaultPath: defaultPath)

        case let .custom(customParams):
            return customParams
        }
    }

    /// Used for Sentry only
    public var name: String {
        switch self {
        case .prod:
            "production"
        case .black:
            "black"
        case let .scientist(name):
            "scientist_\(name)"
        case .custom:
            "custom"
        }
    }

    public var isProd: Bool {
        switch self {
        case .prod:
            true
        default:
            false
        }
    }
}

public struct DoHParameters: Sendable {
    public let signupDomain: String
    public let captchaHost: String
    public let humanVerificationV3Host: String
    public let accountHost: String
    public let defaultHost: String
    public let apiHost: String
    public let defaultPath: String

    public init(signupDomain: String,
                captchaHost: String,
                humanVerificationV3Host: String,
                accountHost: String,
                defaultHost: String,
                apiHost: String,
                defaultPath: String) {
        self.signupDomain = signupDomain
        self.captchaHost = captchaHost
        self.humanVerificationV3Host = humanVerificationV3Host
        self.accountHost = accountHost
        self.defaultHost = defaultHost
        self.apiHost = apiHost
        self.defaultPath = defaultPath
    }
}
