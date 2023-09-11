//
//  MainRobot.swift
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

// swiftlint:disable prefixed_toplevel_constant
import fusion
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUITestsLogin
import ProtonCoreTestingToolkitUITestsPaymentsUI

class SubscriptionTests: LoginBaseTestCase {
    let welcomeRobot = WelcomeRobot()
    let homeRobot = HomeRobot()
    let timeout = 120.0

    func testUpgradeAccountFromFreeToUnlimited() {
        let randomUsername = StringUtils.randomAlphanumericString(length: 8)
        let randomPassword = StringUtils.randomAlphanumericString(length: 8)

        createAccount(randomUsername, randomPassword)

        SigninExternalAccountsCapability()
            .signInWithAccount(userName: randomUsername,
                               password: randomPassword,
                               loginRobot: welcomeRobot.logIn(),
                               retRobot: AutoFillRobot.self)
            .notNowTap(robot: FaceIDRobot.self)
            .noThanks(robot: GetStartedRobot.self)
            .getStartedTap(robot: HomeRobot.self)
            .tapProfile()
            .tapAccountButton()
            .goToManageSubscription()
            .expandPlan(plan: .unlimited)
            .planButtonTap(plan: .unlimited)
            .verifyPayment(robot: PaymentsUIRobot.self, password: "")
            .verifyCurrentPlan(plan: .unlimited)
            .verifyExtendButton()
    }
}


extension PaymentsUIRobot {

    private func currentPlanCellIdentifier(name: String) -> String {
        "CurrentPlanCell.\(name)"
    }

    func verifyCurrentPlan(plan: PaymentsPlan) -> PaymentsUIRobot {
        cell(currentPlanCellIdentifier(name: plan.rawValue)).waitUntilExists().checkExists()
        return self
    }

    @discardableResult
    func verifyExtendButton() -> PaymentsUIRobot {
        let extendSubscriptionText = "PaymentsUIViewController.extendSubscriptionButton"
        button(extendSubscriptionText).waitUntilExists().checkExists()
        return self
    }
}
