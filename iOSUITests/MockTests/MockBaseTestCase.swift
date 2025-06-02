//
// LoginBaseTestCase.swift
// Proton Pass - Created on 2025. 03. 11..
// Copyright (c) 2025 Proton Technologies AG
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

import fusion
import ProtonCoreDoh
import ProtonCoreEnvironment
import ProtonCoreLog
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUITestsCore
import ProtonCoreTestingToolkitProxy
import XCTest

class MockBaseTestCase: ProtonCoreBaseTestCase {

    var doh: DoH {
        if let customDomain = dynamicDomain.map({ "\($0)" }) {
            return CustomServerConfigDoH(
                signupDomain: customDomain,
                captchaHost: "https://\(customDomain)",
                humanVerificationV3Host: "https://\(customDomain)",
                accountHost: "https://\(customDomain)",
                defaultHost: "https://\(customDomain)",
                apiHost: ObfuscatedConstants.blackApiHost,
                defaultPath: ObfuscatedConstants.blackDefaultPath,
                apnEnvironment: .development
            )
        } else {
            return CustomServerConfigDoH(
                signupDomain: ObfuscatedConstants.blackSignupDomain,
                captchaHost: ObfuscatedConstants.blackCaptchaHost,
                humanVerificationV3Host: ObfuscatedConstants.blackHumanVerificationV3Host,
                accountHost: ObfuscatedConstants.blackAccountHost,
                defaultHost: ObfuscatedConstants.blackDefaultHost,
                apiHost: ObfuscatedConstants.blackApiHost,
                defaultPath: ObfuscatedConstants.blackDefaultPath,
                apnEnvironment: .development
            )
        }
    }

    lazy var quarkCommands = Quark().baseUrl(doh)
    lazy var client: ProxyClient = {
        let signUpString = doh.getSignUpString()
        let isMock = signUpString.contains("mock")
        let urlString = isMock ? doh.getAccountHost() : "https://account.mock.\(signUpString)"
        let url = URL(string: urlString)!
        PMLog.info("ProxyClient url: https://account.mock.\(signUpString)")
        return ProxyClient(baseURL: url)
    }()


    override func setUp() {
        let launchArguments = [
            "--isMockedTest"
        ]

        beforeSetUp(bundleIdentifier: "me.proton.pass.iOSUITests", launchArguments: launchArguments)
        super.setUp()
        PMLog.info("UI TEST runs on: " + doh.getAccountHost())

        LogoutRobot().logoutIfNeeded()
    }

    func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
}
