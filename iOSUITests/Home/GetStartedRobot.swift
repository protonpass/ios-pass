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

private let title = "A better way to use Aliases"
private let exploreNowTxt = "Explore now"
private let closeBtnTxt = "Close"
private let notNowTxt = "Not Now"

public final class GetStartedRobot: CoreElements {
    public let verify = Verify()
    
    public final class Verify: CoreElements {
        @discardableResult
        public func isGetStartedShown(timeout: TimeInterval = 10.0) -> GetStartedRobot {
            staticText(title).waitUntilExists(time: timeout).checkExists()
            return GetStartedRobot()
        }
    }
    
    public func tapExploreNow() -> HomeRobot {
        button(exploreNowTxt).tapIfExists(time: 10.0)
        return HomeRobot()
    }
    
    public func tapClose(time: TimeInterval = 15.0) -> HomeRobot {
        button(notNowTxt).tapIfExists(time: time)
        button(closeBtnTxt).tapIfExists(time: 5.0)
        return HomeRobot()
    }
}
