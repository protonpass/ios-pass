//
//  SettingsTests.swift
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

import pmtest
import ProtonCore_ObfuscatedConstants
import ProtonCore_TestingToolkit
import XCTest

class SettingsTests: LoginBaseTestCase {
    let welcomeRobot = WelcomeRobot()
    let homeRobot = HomeRobot()

    
    /// settings and telemetry haven't build yet. enable when ready
    func testTelemetrySettings() {
        welcomeRobot.logIn()
            .fillUsername(username: ObfuscatedConstants.passTestUsername)
            .fillpassword(password: ObfuscatedConstants.passTestPassword)
            .signIn(robot: AutoFillRobot.self)
            .notNowTap(robot: FaceIDRobot.self)
            .noThanks(robot: GetStartedRobot.self)
            .getStartedTap(robot: HomeRobot.self)
            .tapBurgerMenuButton(robot: SettingsRobot.self)
            .tapSettingsButton()
            .verify.telemetryItemIsDisplayed()
    }
}
