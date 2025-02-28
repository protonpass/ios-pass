//
// AccountRobot.swift
// Proton Pass - Created on 2023. 08. 17..
// Copyright (c) 2023. Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import Foundation
import fusion
import ProtonCoreTestingToolkitUnitTestsCore
import ProtonCoreTestingToolkitUITestsCore
import ProtonCoreTestingToolkitUITestsPaymentsUI

fileprivate let upgradeButton = "Upgrade"
fileprivate let deleteAccountButton = "Delete account"
fileprivate let deleteAccountText = "Delete account"
fileprivate let deleteButton = "Delete"

class AccountRobot: CoreElements {

    @discardableResult
    func goToManageSubscription() -> PaymentsUIRobot {
        button(upgradeButton).tap()
        return PaymentsUIRobot()
    }

    func deleteAccount() -> AccountRobot {
        button(deleteAccountButton).tap()
        return AccountRobot()
    }

    let verify = Verify()

    class Verify: CoreElements {

        @discardableResult
        func deleteAccountScreen() -> AccountRobot {
            staticText(deleteAccountText).waitUntilExists(time: 10).checkExists()
            button(deleteButton).waitUntilExists(time: 10).checkExists()
            return AccountRobot()
        }
    }
}
