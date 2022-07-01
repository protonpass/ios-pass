//
// PKDoh.swift
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

import Foundation
import ProtonCore_Doh

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
