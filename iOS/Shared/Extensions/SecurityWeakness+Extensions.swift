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

//        case .exposedEmail:
//            #localized("Exposed emails")
//        case .exposedPassword:
//            #localized("Exposed passwords")
        case .missing2FA:
            #localized("Missing two-factor authentication")
        }
    }

    var subtitleInfo: String {
        switch self {
        case .excludedItems:
            #localized("The following items are excluded from")
        case .weakPasswords:
            #localized("Weak passwords are easier to guess. Generate strong passwords to keep your accounts safe.")
        case .reusedPasswords:
            #localized("Generate unique passwords to increase your security.")
//        case .exposedEmail:
//            #localized("These accounts appear in data breaches. Update your credentials immediately.")
//        case .exposedPassword:
//            #localized("These password appear in data breaches. Update your credentials immediately.")
        case .missing2FA:
            #localized("Logins with sites that have two-factor authentication available but you haven’t set it up yet.")
        default:
            ""
        }
    }

    var infos: String {
        switch self {
        case .excludedItems:
            #localized("This item is not being monitored")
        case .weakPasswords:
            #localized("This account is vulnerable, visit the service and change your password")
        case .reusedPasswords:
            #localized("Visit the website and generate a unique password for this item")
//        case .exposedEmail:
//            ""
//        case .exposedPassword:
//            ""
        case .missing2FA:
            #localized("It would be more secure to set up 2FA for this item")

        default:
            ""
        }
    }
}
