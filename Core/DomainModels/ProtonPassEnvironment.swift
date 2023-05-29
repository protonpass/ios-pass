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

public enum ProtonPassEnvironment {
    case black, prod, custom(DoHParameters)

    public var parameters: DoHParameters {
        switch self {
        case .black:
            return .init(signupDomain: "proton.black",
                         captchaHost: "https://api.proton.black",
                         humanVerificationV3Host: "https://verify.proton.black",
                         accountHost: "https://account.proton.black",
                         defaultHost: "https://proton.black",
                         apiHost: "dmfygsltqojxxi33onvqws3bomnua.protonpro.xyz",
                         defaultPath: "/api")
        case .prod:
            return .init(signupDomain: "proton.me",
                         captchaHost: "https://pass-api.proton.me",
                         humanVerificationV3Host: "https://verify.proton.me",
                         accountHost: "https://account.proton.me",
                         defaultHost: "https://pass-api.proton.me",
                         apiHost: "pass-api.proton.me",
                         defaultPath: "/api")
        case .custom(let customParams):
            return customParams
        }
    }
}

public struct DoHParameters {
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
