//
//  LoginSignupTests.swift
//  iOSUITests
//

import ProtonCore_ObfuscatedConstants
import ProtonCore_QuarkCommands
import ProtonCore_TestingToolkit
import XCTest

class LoginSignupTests: LoginBaseTestCase {
    lazy var quarkCommands = QuarkCommands(doh: doh)
    let mainRobot = MainRobot()

    let password = ObfuscatedConstants.password
    let shortPassword = ObfuscatedConstants.shortPassword
    let emailVerificationCode = ObfuscatedConstants.emailVerificationCode
    let emailVerificationWrongCode = ObfuscatedConstants.emailVerificationWrongCode
    let testEmail = ObfuscatedConstants.testEmail
    let testNumber = ObfuscatedConstants.testNumber
    let exampleCountry = "Swi"
    let exampleCode = "+41"
    let defaultCode = "XXXXXX"
    let existingName = ObfuscatedConstants.existingUsername
    let existingEmail = "\(ObfuscatedConstants.externalUserUsername)@me.com"
    let existingEmailPassword = ObfuscatedConstants.externalUserPassword

    override func setUp() {
        super.setUp()
        mainRobot
            .changeEnvironmentToCustomIfDomainHereBlackOtherwise(dynamicDomainAvailable)
    }

    private func readLocalFile(forName name: String) -> String? {
        do {
            if let bundlePath = Bundle(for: LoginSignupTests.self).path(forResource: name, ofType: "json") {
                let jsonData = try String(contentsOfFile: bundlePath)
                return jsonData
            }
        } catch { }
        return nil
    }

    override func tearDown() {
        super.tearDown()
    }

    // singup tests will enable later
}
