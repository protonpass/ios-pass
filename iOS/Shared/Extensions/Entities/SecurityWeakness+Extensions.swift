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

/// Presentation model for a single weakness row shown on the login detail screen.
///
/// A row either represents one detected `WeaknessKind` (with whether the user has excluded that
/// specific check) or the whole-item "fully excluded" state. Dark Web Monitoring is intentionally
/// not represented here — it has its own route.
enum ItemWeaknessDisplay: Identifiable, Hashable {
    case weakness(WeaknessKind, isExcluded: Bool)
    case fullyExcluded

    var id: Self {
        self
    }

    var isExcluded: Bool {
        switch self {
        case let .weakness(_, isExcluded):
            isExcluded

        case .fullyExcluded:
            true
        }
    }
}

extension ItemWeaknessDisplay {
    var title: String {
        switch self {
        case .fullyExcluded:
            #localized("Excluded Items")

        case .weakness(.compromisedPassword, _), .weakness(.weakPassword, _):
            #localized("Weak passwords")

        case .weakness(.reusedPassword, _):
            #localized("Reused passwords")

        case .weakness(.missing2FA, _):
            #localized("Set up 2FA for more security")
        }
    }

    /// Title used in login detail page
    var detailTitle: String? {
        title
    }

    var subtitleInfo: String? {
        switch self {
        case .weakness(.compromisedPassword, _), .weakness(.weakPassword, _):
            #localized("Weak passwords are easier to guess. Generate strong passwords to keep your accounts safe.")

        case .weakness(.reusedPassword, _):
            #localized("Generate unique passwords for each account to increase your security.")

        case .weakness(.missing2FA, _):
            #localized("For added security, set up two-factor authentication on the following accounts.")

        default:
            nil
        }
    }

    var infos: String? {
        switch self {
        case .fullyExcluded:
            #localized("This item is not being monitored")

        case .weakness(.compromisedPassword, _), .weakness(.weakPassword, _):
            #localized("This account is vulnerable, visit the service and change your password")

        case .weakness(.missing2FA, _):
            #localized("This service offers 2FA. Enable it for added account security.")

        default:
            nil
        }
    }
}

// MARK: - MonitorWeaknessFilter presentation

extension MonitorWeaknessFilter {
    var title: String {
        switch self {
        case .excludedItems:
            #localized("Excluded Items")

        case .weakness(.compromisedPassword), .weakness(.weakPassword):
            #localized("Weak passwords")

        case .weakness(.reusedPassword):
            #localized("Reused passwords")

        case .weakness(.missing2FA):
            #localized("Set up 2FA for more security")
        }
    }

    var subtitleInfo: String? {
        switch self {
        case .weakness(.compromisedPassword), .weakness(.weakPassword):
            #localized("Weak passwords are easier to guess. Generate strong passwords to keep your accounts safe.")

        case .weakness(.reusedPassword):
            #localized("Generate unique passwords for each account to increase your security.")

        case .weakness(.missing2FA):
            #localized("For added security, set up two-factor authentication on the following accounts.")

        default:
            nil
        }
    }

    var nothingWrongMessage: String {
        switch self {
        case .weakness(.compromisedPassword), .weakness(.weakPassword):
            #localized("No weak passwords were found in your login items")

        case .weakness(.reusedPassword):
            #localized("You have no reused passwords in your login items")

        case .weakness(.missing2FA):
            #localized("All your login items have two-factor authentication enabled")

        case .excludedItems:
            #localized("You don't have any excluded login items from monitoring")
        }
    }

    var telemetryEventType: TelemetryEventType {
        switch self {
        case .weakness(.compromisedPassword), .weakness(.weakPassword):
            .monitorDisplayWeakPasswords

        case .weakness(.reusedPassword):
            .monitorDisplayReusedPasswords

        case .weakness(.missing2FA):
            .monitorDisplayMissing2FA

        case .excludedItems:
            .monitorDisplayExcludedItems
        }
    }
}
