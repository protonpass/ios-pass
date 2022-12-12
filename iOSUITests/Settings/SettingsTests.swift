//
//  SettingsTests.swift
//  SampleAppUITests
//
//  Created by Kristina Jureviciute on 2021-04-23.
//

import pmtest
import ProtonCore_ObfuscatedConstants
import ProtonCore_TestingToolkit
import XCTest

class SettingsTests: LoginBaseTestCase {
    let welcomeRobot = WelcomeRobot()
    let homeRobot = HomeRobot()

    func testTelemetrySettings() {
        welcomeRobot.logIn()
            .fillUsername(username: ObfuscatedConstants.passTestUsername)
            .fillpassword(password: ObfuscatedConstants.passTestPassword)
            .signIn(robot: HomeRobot.self)
            .tapBurgerMenuButton(robot: SettingsRobot.self)
            .tapSettingsButton()
            .verify.telemetryItemIsDisplayed()
    }
}
