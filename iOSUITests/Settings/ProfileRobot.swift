//
//  ProfileRobot.swift
//  Proton Pass - Created on 12/23/22.
//
// Copyright (c) 2023. Proton Technologies AG
//
// This file is part of Proton Pass.
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

private let storageLabelText = "Storage"
private let expandProfile = "ProfileTabView.AccountSection.AccountCell"
private let popupButton = "SwiftUIImage"
private let signOutButton = "Sign out"
private let accountLabelText = "Account"
private let addAccountButtonText = "Add account"

final class ProfileRobot: CoreElements {
    let verify = Verify()

    public final class Verify: CoreElements {
        @discardableResult
        public func itemListContainsAllElements(login: String, alias: String, creditCard: String, note: String) -> ProfileRobot {
            staticText(storageLabelText).waitUntilExists().checkExists()
            staticText(login).waitUntilExists().checkExists()
            staticText(alias).waitUntilExists().checkExists()
            staticText(creditCard).waitUntilExists().checkExists()
            staticText(note).waitUntilExists().checkExists()
            return ProfileRobot()
        }
    }

    func tapExpandProfile() -> ProfileRobot {
        staticText(accountLabelText).waitUntilExists().checkExists()
        scrollView().onDescendant(image().byIndex(0)).tap()
        return self
    }

    func tapExpandMenu() -> ProfileRobot {
        staticText(addAccountButtonText).waitUntilExists().checkExists()
        image("SwiftUIImage").byIndex(2).tap()
        return self
    }

    func signOut() {
        button(signOutButton).tap()
        button(signOutButton).tap()
    }

    func tapAccountButton() -> AccountRobot {
        staticText(accountLabelText).waitUntilExists().tap()
        return AccountRobot()
    }
}
