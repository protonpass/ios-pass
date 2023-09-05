//
//  LoginWelcomeTests.swift
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
import ProtonCoreTestingToolkitUnitTestsCore
import XCTest
import ProtonCoreTestingToolkitUITestsLogin

final class LoginWelcomeTests: LoginBaseTestCase {
    let welcomeRobot = WelcomeRobot()

    override func setUp() {
        super.setUp()
    }

    func testMailWelcomeScreenIsShown() {
        welcomeRobot
            .verify.welcomeScreenVariantIsNotShown(variant: .mail)
            .verify.welcomeScreenVariantIsNotShown(variant: .vpn)
            .verify.welcomeScreenVariantIsNotShown(variant: .drive)
            .verify.welcomeScreenVariantIsNotShown(variant: .calendar)
    }

    func testSignUpButtonIsPresentedOnWelcomeScreenWhenItShouldBe() {
        welcomeRobot
            .verify.signUpButtonExists()
    }

    func testLoginButtonIsPresentedOnWelcomeScreenWhenItShouldBe() {
        welcomeRobot
            .verify.loginButtonExists()
    }

    func testLoginButtonLeadsToSignUpLessLoginScreenWhenNeeded() {
        welcomeRobot
            .logIn()
            .verify.switchToCreateAccountButtonIsShown()
    }

    func testSignUpButtonLeadsToSignUpScreen() {
        welcomeRobot
            .signUp()
            .verify.closeButtonIsShown()
    }

    func testLoginButtonLeadsToLoginScreen() {
        welcomeRobot
            .logIn()
            .verify.closeButtonIsShown()
    }
}
