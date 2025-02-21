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
import ProtonCoreQuarkCommands
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUITestsLogin
import ProtonCoreTestingToolkitUITestsPaymentsUI
import StoreKitTest
import Testing

class SubscriptionTests: LoginBaseTestCase {
    private let welcomeRobot = WelcomeRobot()
    private let homeRobot = HomeRobot()
    private var session: SKTestSession!

    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "Proton Pass - Password Manager")
        session.disableDialogs = true
        session.clearTransactions()
    }

    fileprivate func createUserVerifySubscription(plan: PaymentsPlan) throws {
        let user = User(name: randomName, password: randomPassword)
        try quarkCommands.userCreate(user: user)
        
        SigninExternalAccountsCapability()
            .signInWithAccount(userName: user.name,
                               password: user.password,
                               loginRobot: welcomeRobot.logIn(),
                               retRobot: GetStartedRobot.self)
            .tapClose()
            .tapProfile()
            .tapAccountButton()
            .goToManageSubscription()
            .expandPlan(plan: plan)
            .planButtonTap(plan: plan)
        
        PaymentsUIRobot()
            .verifyCurrentPlan(plan: plan)
            .verifyExtendButton()
    }

    func testUpgradeAccountFromFreeToUnlimited() throws {
        try createUserVerifySubscription(plan: .unlimited)
    }

    func testUpgradeAccountFromFreeToPlus() throws {
        try createUserVerifySubscription(plan: .pass2022)
    }
}
