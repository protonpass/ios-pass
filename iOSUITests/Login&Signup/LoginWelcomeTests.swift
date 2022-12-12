//
//  LoginWelcomeTests.swift
//  SampleAppUITests
//
//  Created by Krzysztof Siejkowski on 28/06/2021.
//

import pmtest
import ProtonCore_TestingToolkit
import XCTest

final class LoginWelcomeTests: LoginBaseTestCase {
    let welcomeRobot = WelcomeRobot()

    override func setUp() {
        super.setUp()
    }

    func testMailWelcomeScreenIsShown() {
        welcomeRobot
            .verify.welcomeScreenVariantIsNotShown(variant: .mail)
    }

    // pass right now use .drive temperaly
    func testDriveWelcomeScreenIsShown() {
        welcomeRobot
            .verify.welcomeScreenVariantIsShown(variant: .drive)
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
