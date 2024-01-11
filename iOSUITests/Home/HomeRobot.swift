//
//  HomeRobot.swift
//  Proton Pass - Created on 11/02/2022
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

// swiftlint:disable prefixed_toplevel_constant
import fusion
import ProtonCoreTestingToolkitUITestsCore
import XCTest

private let emptyViewText = "Create your first item\n by clicking the button below"
private let burgerMenuButtonIdentifier = "Button.BurgerMenu"
private let profileTab = "HomepageTabBarController_profileTabView"

public final class HomeRobot: CoreElements {
    public let verify = Verify()

    public final class Verify: CoreElements {
        @discardableResult
        public func emptyVaultViewIsShown(timeout: TimeInterval = 10.0) -> HomeRobot {
            staticText(emptyViewText).waitUntilExists(time: timeout).checkExists()
            return HomeRobot()
        }
    }

    func tapBurgerMenuButton<T: CoreElements>(robot _: T.Type) -> T {
        button(burgerMenuButtonIdentifier).waitUntilExists().tap()
        return T()
    }

    @discardableResult
    func tapProfile() -> ProfileRobot {
        button(profileTab).waitUntilExists().tap()
        return ProfileRobot()
    }
}

extension Wait {
    @MainActor
    func waitUntilExists(timeInterval: TimeInterval) {
        let testCase = XCTestCase()
        let waitExpectation = testCase.expectation(description: "Waiting")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + timeInterval) {
            waitExpectation.fulfill()
        }
        testCase.waitForExpectations(timeout: timeInterval + 0.5)
    }
}
