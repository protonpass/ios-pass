//
//  TokenRefreshTests.swift
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

import Foundation

import pmtest
import ProtonCore_Environment
import ProtonCore_QuarkCommands
import ProtonCore_TestingToolkit
import XCTest

final class TokenRefreshTests: LoginBaseTestCase {
    let welcomeRobot = WelcomeRobot()

    func testSignInWithInternalAccountWorks() {
        let doh = Environment.black.doh
        let randomUsername = StringUtils.randomAlphanumericString(length: 8)
        let randomPassword = StringUtils.randomAlphanumericString(length: 8)
        let expectQuarkCommandToFinish = expectation(description: "Quark command should finish")
        var quarkCommandResult: Result<CreatedAccountDetails, CreateAccountError>?
        QuarkCommands.create(account: .freeWithAddressAndKeys(username: randomUsername, password: randomPassword),
                             currentlyUsedHostUrl: Environment.black.doh.getCurrentlyUsedHostUrl()) { result in
            quarkCommandResult = result
            QuarkCommands.addPassScopeToUser(username: randomUsername,
                                             currentlyUsedHostUrl: doh.getCurrentlyUsedHostUrl()) { result in
                if case .failure(let error) = result {
                    XCTFail("\(error)")
                }
                expectQuarkCommandToFinish.fulfill()
            }
        }
        wait(for: [expectQuarkCommandToFinish], timeout: 5.0)
        if case .failure(let error) = quarkCommandResult {
            XCTFail("Internal account creation failed: \(error.userFacingMessageInQuarkCommands)")
            return
        }
        welcomeRobot.logIn()
            .fillUsername(username: randomUsername)
            .fillpassword(password: randomPassword)
            .signIn(robot: OnboardingRobot.self)
            .verify.isOnboardingViewShown()
        let expectExpireSessionQuarkCommandToFinish = expectation(description: "Quark command should finish")
        QuarkCommands.expireSession(currentlyUsedHostUrl: Environment.black.doh.getCurrentlyUsedHostUrl(),
                                    username: randomUsername,
                                    expireRefreshToken: true) {result in
            if case .failure(let error) = result {
                XCTFail("\(error)")
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10.0) {
                expectExpireSessionQuarkCommandToFinish.fulfill()
            }
        }
        wait(for: [expectExpireSessionQuarkCommandToFinish], timeout: 15.0)
        WelcomeRobot().verify.loginButtonExists()
    }
}
