//
// SecurityWeakness+Extensions.swift
// Proton Pass - Created on 08/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities

public extension SecurityWeakness {
    var title: String {
        switch self {
        case .excludedItems:
            "Excluded Items"
        case .weakPasswords:
            "Weak passwords"
        case .reusedPasswords:
            "Reused passwords"
        case .exposedEmail:
            "Exposed emails"
        case .exposedPassword:
            "Exposed passwords"
        case .missing2FA:
            "Missing two-factor authentication"
        }
    }

    var subtitleInfo: String {
        switch self {
        case .excludedItems:
            "The following items are excluded from "
        case .weakPasswords:
            "Weak passwords are easier to guess. Generate strong passwords to keep your accounts safe."
        case .reusedPasswords:
            "Generate unique passwords to increase your security."
        case .exposedEmail:
            "These accounts appear in data breaches. Update your credentials immediately."
        case .exposedPassword:
            "These password appear in data breaches. Update your credentials immediately."
        case .missing2FA:
            "Logins with sites that have two-factor authentication available but you haven’t set it up yet."
        }
    }

    var infos: String {
        switch self {
        case .excludedItems:
            ""
        case .weakPasswords:
            "This account is vulnerable, visit the service and change your password."
        case .reusedPasswords:
            ""
        case .exposedEmail:
            ""
        case .exposedPassword:
            ""
        case .missing2FA:
            ""
        }
    }
}
