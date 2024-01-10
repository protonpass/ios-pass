//
//  LoginSignupTests.swift
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

//import ProtonCoreObfuscatedConstants
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUnitTestsCore
import XCTest

class LoginSignupTests: LoginBaseTestCase {
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
    // signup tests will enable later
}
