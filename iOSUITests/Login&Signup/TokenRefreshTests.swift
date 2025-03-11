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
import fusion
import ProtonCoreEnvironment
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUITestsLogin
import XCTest

final class TokenRefreshTests: LoginBaseTestCase {
    let welcomeRobot = WelcomeRobot()
    
    func testSignInWithInternalAccountWorks() throws {
        let user = User(name: randomName, password: randomPassword)
        try quarkCommands.userCreate(user: user)
        try quarkCommands.jailUnban()
        
        let homeRobot = welcomeRobot.logIn()
            .fillUsername(username: user.name)
            .fillpassword(password: user.password)
            .signIn(robot: GetStartedRobot.self)
            .dismissWelcomeScreen()
        
        _ = try quarkCommands.userExpireSession(username: user.name, expireRefreshToken: true)
        
        homeRobot
            .tapProfile()
        
        WelcomeRobot()
            .clickOnExpireSessionPopup()
            .verify.loginButtonExists()
    }
}

extension WelcomeRobot {
    
    public func clickOnExpireSessionPopup() -> WelcomeRobot {
        staticText("Your session is expired").waitUntilExists(time: 30.0).checkExists()
        button("OK").tap()
        return self
    }
    
}
