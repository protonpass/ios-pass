//
//  LoginBaseTestCase.swift
//  iOSUITests - Created on 12/23/22.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import fusion
import ProtonCoreDoh
import ProtonCoreEnvironment
import ProtonCoreLog
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUITestsCore
import XCTest

class LoginBaseTestCase: ProtonCoreBaseTestCase {

    var doh: DoH {

        if let customDomain = dynamicDomain.map({ "\($0)" }) {
            let isMock = customDomain.contains("mock")

            let captchaHost = isMock ? "https://\(customDomain)" : "https://api.\(customDomain)"
            let humanVerificationV3Host = isMock ? "https://\(customDomain)" : "https://verify.\(customDomain)"
            let accountHost = isMock ? "https://\(customDomain)" : "https://account.\(customDomain)"
            let defaultHost = "https://\(customDomain)"

            return CustomServerConfigDoH(
                signupDomain: customDomain,
                captchaHost: captchaHost,
                humanVerificationV3Host: humanVerificationV3Host,
                accountHost: accountHost,
                defaultHost: defaultHost,
                apiHost: ObfuscatedConstants.blackApiHost,
                defaultPath: ObfuscatedConstants.blackDefaultPath,
                apnEnvironment: .development
            )
        }

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

    let entryRobot = AppMainRobot()
    var appRobot: MainRobot!
    lazy var quarkCommands = Quark().baseUrl(doh)

    override func setUp() {
        beforeSetUp(bundleIdentifier: "me.proton.pass.iOSUITests")
        super.setUp()
        PMLog.info("UI TEST runs on: " + doh.getAccountHost())

        LogoutRobot().logoutIfNeeded()
    }
}
