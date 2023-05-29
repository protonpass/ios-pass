//
// PPDoH.swift
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

import ProtonCore_Doh

public final class ProtonPassDoH: DoH, ServerConfig {
    public let signupDomain: String
    public let captchaHost: String
    public let humanVerificationV3Host: String
    public let accountHost: String
    public let defaultHost: String
    public let apiHost: String
    public let defaultPath: String

    public init(environment: ProtonPassEnvironment) {
        let params = environment.parameters
        self.signupDomain = params.signupDomain
        self.captchaHost = params.captchaHost
        self.humanVerificationV3Host = params.humanVerificationV3Host
        self.accountHost = params.accountHost
        self.defaultHost = params.defaultHost
        self.apiHost = params.apiHost
        self.defaultPath = params.defaultHost
    }
}
