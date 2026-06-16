//
// ItemWeaknessDisplay+Extensions.swift
// Proton Pass - Created on 16/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Client
import DesignSystem
import Entities
import Foundation
import Macro
import SwiftUI

extension ItemWeaknessDisplay {
    var title: String {
        switch self {
        case .fullyExcluded:
            #localized("Excluded Item")

        case .weakness(.compromisedPassword, _), .weakness(.weakPassword, _):
            #localized("Weak password")

        case .weakness(.reusedPassword, _):
            #localized("Reused password")

        case .weakness(.missing2FA, _):
            #localized("Set up 2FA for more security")
        }
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

    var icon: Image? {
        switch self {
        case .weakness(.missing2FA, _):
            PassIcon.shieldLockPurple

        case .weakness(.reusedPassword, _):
            PassIcon.reusedKey

        case .weakness(.compromisedPassword, _), .weakness(.weakPassword, _):
            PassIcon.shieldBad

        case .fullyExcluded:
            PassIcon.shieldWarning
        }
    }

    var shortTitle: String {
        switch self {
        case .weakness(.missing2FA, _):
            #localized("Missing 2FA")

        default:
            title
        }
    }

    var color: Color {
        switch self {
        case .weakness(.compromisedPassword, _), .weakness(.weakPassword, _):
            PassColor.passwordInteractionNormMajor2

        case .fullyExcluded, .weakness(.reusedPassword, _):
            PassColor.noteInteractionNormMajor2

        default:
            PassColor.textNorm
        }
    }

    var flag: ItemFlag? {
        switch self {
        case let .weakness(.missing2FA, isExcluded):
            .skip2FACheck(!isExcluded)

        case let .weakness(.reusedPassword, isExcluded):
            .skipReusedPasswordCheck(!isExcluded)

        case let .weakness(.weakPassword, isExcluded):
            .skipWeakPasswordCheck(!isExcluded)

        case let .weakness(.compromisedPassword, isExcluded):
            .skipCompromisedPasswordCheck(!isExcluded)

        case .fullyExcluded:
            // Full-item monitoring is a stateful toggle handled by `toggleMonitoring(weakness:)`;
            // its direction depends on the item's live monitoring state, not on `isExcluded`.
            nil
        }
    }
}
