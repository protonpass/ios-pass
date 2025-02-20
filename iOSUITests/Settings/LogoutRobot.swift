//
// LogoutRobot.swift
// Proton Pass - Created on 2025. 02. 14..
// Copyright (c) 2025 Proton Technologies AG
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

<<<<<<< HEAD
import fusion

class LogoutRobot: ElementsProtocol {

    func logoutIfNeeded() {
        if button("Sign in").exists() {
            return
        }

=======
enum LogoutRobot {
    static func logoutIfNeeded() {
>>>>>>> e067f48e4 (TPE-981 - resurrect ui tests)
        if HomeRobot().verify.isProfileTabExist() {
            GetStartedRobot()
                .tapClose()
                .tapProfile()
                .tapExpandProfile()
                .tapExpandMenu()
                .signOut()
        }
    }
}
