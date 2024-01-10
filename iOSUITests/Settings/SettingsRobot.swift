//
//  MainRobot.swift
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

private let settingsLabelText = "Settings"

final class SettingsRobot: CoreElements {
    let verify = Verify()

    final class Verify: CoreElements {
    }

    func tapSettingsButton() -> SettingsRobot {
        button(settingsLabelText).waitUntilExists().tap()
        return self
    }
}
