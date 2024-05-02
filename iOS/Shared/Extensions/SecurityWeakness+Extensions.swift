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
import Macro

public extension SecurityWeakness {
    var title: String {
        switch self {
        case .excludedItems:
            #localized("Excluded Items")
        case .weakPasswords:
            #localized("Weak passwords")
        case .reusedPasswords:
            #localized("Reused passwords")
        case .breaches:
            #localized("Dark Web Monitoring")
        case .missing2FA:
            #localized("Set up 2FA for more security")
        }
    }

    /// Title used in login detail page
    var detailTitle: String? {
        switch self {
        case .reusedPasswords:
            nil
        default:
            title
        }
    }

    var subtitleInfo: String? {
        switch self {
        case .weakPasswords:
            #localized("Weak passwords are easier to guess. Generate strong passwords to keep your accounts safe.")
        case .reusedPasswords:
            #localized("Generate unique passwords for each account to increase your security.")
        case .missing2FA:
            #localized("For added security, set up two-factor authentication on the following accounts.")
        default:
            nil
        }
    }

    var infos: String? {
        switch self {
        case .excludedItems:
            #localized("This item is not being monitored")
        case .weakPasswords:
            #localized("This account is vulnerable, visit the service and change your password")
        case .missing2FA:
            #localized("This service offers 2FA. Enable it for added account security.")
        default:
            nil
        }
    }
}
