//
// ItemWeaknessDisplay+Extensions.swift
// Proton Pass - Created on 24/09/2026.
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

import DesignSystem
import Entities
import Foundation
import Macro
import SwiftUI

public extension ItemWeaknessDisplay {
    var title: String {
        switch self {
        case .fullyExcluded:
            #localized("Excluded Item", bundle: .module)

        case .weakness(.weakPassword, _):
            #localized("Weak password", bundle: .module)

        case .weakness(.compromisedPassword, _):
            #localized("Compromised password", bundle: .module)

        case .weakness(.reusedPassword, _):
            #localized("Reused password", bundle: .module)

        case .weakness(.missing2FA, _):
            #localized("Set up 2FA for more security", bundle: .module)
        }
    }

    var infos: String? {
        switch self {
        case .fullyExcluded:
            #localized("This item is not being monitored", bundle: .module)

        case .weakness(.compromisedPassword, _):
            #localized("Password exposed on the dark web.", bundle: .module)

        case .weakness(.weakPassword, _):
            #localized("This account is vulnerable, visit the service and change your password", bundle: .module)

        case .weakness(.missing2FA, _):
            #localized("This service offers 2FA. Enable it for added account security.", bundle: .module)

        case .weakness(.reusedPassword, _):
            nil
        }
    }

    @MainActor
    var icon: Image {
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
            #localized("Missing 2FA", bundle: .module)

        case .fullyExcluded,
             .weakness(.compromisedPassword, _),
             .weakness(.reusedPassword, _),
             .weakness(.weakPassword, _):
            title
        }
    }

    @MainActor
    var color: Color {
        switch self {
        case .weakness(.compromisedPassword, _), .weakness(.weakPassword, _):
            PassColor.passwordInteractionNormMajor2

        case .fullyExcluded, .weakness(.reusedPassword, _):
            PassColor.noteInteractionNormMajor2

        case .weakness(.missing2FA, _):
            PassColor.textNorm
        }
    }

    func flag(_ isFullyMonitored: Bool) -> ItemFlag {
        switch self {
        case let .weakness(kind, isExcluded):
            // `isExcluded` means the check is currently suppressed; toggling restores it, hence
            // `skipped: !isExcluded`. The kind↔flag mapping lives once in `ItemFlag.skip`.
            .skip(kind, !isExcluded)

        case .fullyExcluded:
            .skipHealthCheck(isFullyMonitored)
        }
    }
}
