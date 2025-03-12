//
//  ExternalAccountsTests.swift
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

import fusion
import ProtonCoreDoh
import ProtonCoreEnvironment
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUITestsLogin
import XCTest

final class ExternalAccountsTests: LoginBaseTestCase {
    let timeout = 60.0

    let welcomeRobot = WelcomeRobot()

    // Sign-in with internal account works
    // Sign-in with external account works
    // Sign-in with username account works (account is converted to internal under the hood)
    func testSignInWithInternalAccountWorks() throws {
        let user = User(name: randomName, password: randomPassword)
        try quarkCommands.userCreate(user: user)
        
        SigninExternalAccountsCapability()
            .signInWithAccount(userName: user.name,
                               password: user.password,
                               loginRobot: welcomeRobot.logIn(),
                               retRobot: GetStartedRobot.self)
            .dismissWelcomeScreen()
            .verify.emptyVaultViewIsShown()
    }

    func testSignInWithExternalAccountWorks() throws {
        let user = User(email: randomEmail, name: randomName, password: randomPassword, isExternal: true)
        try quarkCommands.userCreate(user: user)

        SigninExternalAccountsCapability()
            .signInWithAccount(userName: user.email,
                               password: user.password,
                               loginRobot: welcomeRobot.logIn(),
                               retRobot: GetStartedRobot.self)
            .dismissWelcomeScreen()
            .verify.emptyVaultViewIsShown()
    }

    // Sign-up with internal account works
    // Sign-up with external account works
    // The UI for sign-up with username account is not available
    // FIXME: Enable again when Account team provides a working solution
    func disableTestSignUpWithInternalAccountWorks() throws {
        let randomUsername = StringUtils.randomAlphanumericString(length: 8)
        let randomPassword = StringUtils.randomAlphanumericString(length: 8)
        let randomEmail = "\(StringUtils.randomAlphanumericString(length: 8))@proton.uitests"

        try quarkCommands.jailUnban()
        
        let signupRobot = welcomeRobot
            .logIn()
            .switchToCreateAccount()
            .otherAccountButtonTap()
            .verify.otherAccountExtButtonIsShown()

        SignupExternalAccountsCapability()
            .signUpWithInternalAccount(
                signupRobot: signupRobot,
                username: randomUsername,
                password: randomPassword,
                userEmail: randomEmail,
                verificationCode: "666666",
                retRobot: GetStartedRobot.self
            ).dismissWelcomeScreen()
            .verify.emptyVaultViewIsShown()
    }

    // FIXME: Enable again when Account team provides a working solution
    func disabledTestSignUpWithExternalAccountIsNotAvailable() throws {
        let randomPassword = StringUtils.randomAlphanumericString(length: 8)
        let randomEmail = "\(StringUtils.randomAlphanumericString(length: 8))@example.com"

        try quarkCommands.jailUnban()

        let signupRobot = welcomeRobot
            .logIn()
            .switchToCreateAccount()
            .verify.otherAccountIntButtonIsShown()

        SignupExternalAccountsCapability()
            .signUpWithExternalAccount(
                signupRobot: signupRobot,
                userEmail: randomEmail,
                password: randomPassword,
                verificationCode: "666666",
                retRobot: HomeRobot.self
            )
            .verify.emptyVaultViewIsShown()
    }

    func testSignUpWithExternalAccountIsNotAvailable() {
        welcomeRobot
            .signUp()
            .verify.otherAccountExtButtonIsNotShown()
    }

    func testSignUpWithUsernameAccountIsNotAvailable() {
        welcomeRobot.logIn()
            .switchToCreateAccount()
            .otherAccountButtonTap()
            .verify.otherAccountExtButtonIsShown()
            .verify.domainsButtonIsShown()
    }
}
