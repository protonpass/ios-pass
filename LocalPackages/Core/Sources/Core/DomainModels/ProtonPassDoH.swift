//
// ProtonPassDoH.swift
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

import Foundation
import ProtonCoreDoh

// swiftlint:disable:next force_unwrapping
public let kSharedUserDefaults = UserDefaults(suiteName: Constants.appGroup)!

public final class ProtonPassDoH: DoH, ServerConfig {
    public let environment: ProtonPassEnvironment
    public let signupDomain: String
    public let captchaHost: String
    public let humanVerificationV3Host: String
    public let accountHost: String
    public let defaultHost: String
    // periphery:ignore
    public let apiHost: String
    public let defaultPath: String
    public let proxyToken: String?

    public init(bundle: Bundle = .main, userDefaults: UserDefaults = kSharedUserDefaults) {
        let environment: ProtonPassEnvironment
        if bundle.isQaBuild {
            switch userDefaults.string(forKey: "pref_environment") {
            case "black":
                environment = .black
            case "prod":
                environment = .prod
            case "scientist":
                let name = userDefaults.string(forKey: "pref_scientist_env_name")
                environment = .scientist(name ?? "")
            case "custom":
                let signupDomain = userDefaults.string(forKey: "pref_custom_env_sign_up_domain")
                let captchaHost = userDefaults.string(forKey: "pref_custom_env_captcha_host")
                let hvHost = userDefaults.string(forKey: "pref_custom_env_human_verification_host")
                let accountHost = userDefaults.string(forKey: "pref_custom_env_account_host")
                let defaultHost = userDefaults.string(forKey: "pref_custom_env_default_host")
                let apiHost = userDefaults.string(forKey: "pref_custom_env_api_host")
                let defaultPath = userDefaults.string(forKey: "pref_custom_env_default_path")
                environment = .custom(DoHParameters(signupDomain: signupDomain ?? "proton.me",
                                                    captchaHost: captchaHost ?? "https://pass-api.proton.me",
                                                    humanVerificationV3Host: hvHost ?? "https://verify.proton.me",
                                                    accountHost: accountHost ?? "https://account.proton.me",
                                                    defaultHost: defaultHost ?? "https://pass-api.proton.me",
                                                    apiHost: apiHost ?? "pass-api.proton.me",
                                                    defaultPath: defaultPath ?? "/api"))
            default:
                // Fallback to "Automatic" mode
                #if DEBUG
                environment = .black
                #else
                environment = .prod
                #endif
            }
        } else {
            // Always point to prod when not in QA build
            environment = .prod
        }

        self.environment = environment
        let params = environment.parameters
        signupDomain = params.signupDomain
        captchaHost = params.captchaHost
        humanVerificationV3Host = params.humanVerificationV3Host
        accountHost = params.accountHost
        defaultHost = params.defaultHost
        apiHost = params.apiHost
        defaultPath = params.defaultPath
        proxyToken = userDefaults.string(forKey: "pref_custom_env_proxy_token")?.nilIfEmpty
    }
}
