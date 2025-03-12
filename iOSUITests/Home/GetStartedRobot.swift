//
//  GetStartedRobot.swift
//  iOSUITests - Created on 02/21/2023
//
//  Copyright (c) 2023 Proton Technologies AG
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

// swiftlint:disable prefixed_toplevel_constant
import fusion
import ProtonCoreTestingToolkitUITestsCore
import XCTest

private let messageTxt = "The app is now ready to use"
private let startUsingProtonPassTxt = "Start using Proton Pass"
private let closeBtnTxt = "Close"
private let notNowTxt = "Not now"

public final class GetStartedRobot: CoreElements {
    
    public func tapStartUsingProtonPass() -> HomeRobot {
        button(startUsingProtonPassTxt).tapIfExists(time: 10.0)
        return HomeRobot()
    }
    
    public func dismissWelcomeScreen(time: TimeInterval = 20.0) -> HomeRobot {
        for _ in 0..<2 {
            staticText(messageTxt).waitUntilGone(time: time).checkDoesNotExist()
            button(notNowTxt).tapIfExists(time: 5)
        }
        button(startUsingProtonPassTxt).tapIfExists(time: time)
        button(closeBtnTxt).firstMatch().tapIfExists(time: 5.0)
        return HomeRobot()
    }
}
