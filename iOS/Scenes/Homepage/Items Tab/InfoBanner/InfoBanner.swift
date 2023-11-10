//
// InfoBanner.swift
// Proton Pass - Created on 26/05/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Macro
import SwiftUI

enum InfoBanner: CaseIterable, Equatable, Hashable {
    static var allCases: [InfoBanner] {
        [.trial, .autofill, .aliases]
    }

    case trial, autofill, aliases, invite([UserInvite])

    var id: String {
        switch self {
        case .trial:
            "trial"
        case .autofill:
            "autofill"
        case .aliases:
            "aliases"
        case .invite:
            "invite"
        }
    }

    var detail: InfoBannerDetail {
        switch self {
        case .trial:
            .init(title: #localized("Our welcome gift to you"),
                  // swiftlint:disable:next line_length
                  description: #localized("7 days to try premium features for free. Only during your first week of Proton Pass."),
                  icon: nil,
                  ctaTitle: #localized("Learn more"),
                  backgroundColor: PassColor.noteInteractionNormMajor1.toColor,
                  foregroundColor: PassColor.textInvert.toColor)
        case .autofill:
            .init(title: #localized("Enjoy the magic of AutoFill"),
                  description: #localized("One tap and⏤presto!⏤your username and password are filled in instantly"),
                  icon: PassIcon.infoBannerAutoFill,
                  ctaTitle: #localized("Turn on AutoFill"),
                  backgroundColor: PassColor.aliasInteractionNormMajor1.toColor,
                  foregroundColor: PassColor.textInvert.toColor)

        case .aliases:
            .init(title: #localized("Goodbye spam and scams"),
                  description: #localized("Use email aliases to protect your inbox and identity"),
                  icon: PassIcon.infoBannerAliases,
                  ctaTitle: #localized("Learn more"),
                  backgroundColor: PassColor.signalSuccess.toColor,
                  foregroundColor: PassColor.textInvert.toColor)
        case .invite:
            .init(title: #localized("Vault shared with you"),
                  description: #localized("You're invited to a shared vault. Tap for details."),
                  icon: PassIcon.inviteBannerIcon,
                  ctaTitle: nil,
                  backgroundColor: PassColor.backgroundMedium.toColor,
                  foregroundColor: PassColor.textNorm.toColor)
        }
    }

    var isInvite: Bool {
        if case .invite = self { return true }
        return false
    }
}

struct InfoBannerDetail {
    let title: String
    let description: String
    let icon: UIImage?
    /// Call-to-action button title
    let ctaTitle: String?
    let backgroundColor: Color
    let foregroundColor: Color
}
