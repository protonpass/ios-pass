//
//  LoginBaseTestCase.swift
//  iOSUITests
//

import pmtest
import ProtonCore_Doh
import ProtonCore_Log
import ProtonCore_ObfuscatedConstants
import ProtonCore_TestingToolkit
import XCTest

class LoginBaseTestCase: ProtonCoreBaseTestCase {
    let testData = TestData()
    var doh: DoHInterface {
        if let customDomain = dynamicDomain.map({ "\($0)" }) {
            return CustomServerConfigDoH(
                signupDomain: customDomain,
                captchaHost: "https://api.\(customDomain)",
                humanVerificationV3Host: "https://verify.\(customDomain)",
                accountHost: "https://account.\(customDomain)",
                defaultHost: "https://\(customDomain)",
                apiHost: ObfuscatedConstants.blackApiHost,
                defaultPath: ObfuscatedConstants.blackDefaultPath
            )
        } else {
            return CustomServerConfigDoH(
                signupDomain: ObfuscatedConstants.blackSignupDomain,
                captchaHost: ObfuscatedConstants.blackCaptchaHost,
                humanVerificationV3Host: ObfuscatedConstants.blackHumanVerificationV3Host,
                accountHost: ObfuscatedConstants.blackAccountHost,
                defaultHost: ObfuscatedConstants.blackDefaultHost,
                apiHost: ObfuscatedConstants.blackApiHost,
                defaultPath: ObfuscatedConstants.blackDefaultPath
            )
        }
    }

    let entryRobot = AppMainRobot()
    var appRobot: MainRobot!

    override func setUp() {
        beforeSetUp(bundleIdentifier: "me.proton.pass.ios.iOSUITests")
        super.setUp()
    }
}
