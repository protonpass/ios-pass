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

    case trial, autofill, aliases, invite([UserInvite]), slSync(Int)

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
        case .slSync:
            "slSync"
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
        case let .slSync(missingAliases):
            .init(title: #localized("Enable SimpleLogin sync"),
                  // swiftlint:disable:next line_length
                  description: #localized("We detected that you have %lld aliases that are present in SimpleLogin but missing in Proton Pass. Would you like to import them?",
                                          missingAliases),
                  icon: PassIcon.slSyncIcon,
                  ctaTitle: #localized("Sync aliases"),
                  backgroundColor: PassColor.aliasInteractionNormMinor1.toColor,
                  foregroundColor: PassColor.textNorm.toColor,
                  closeButtonColor: PassColor.textNorm.toColor,
                  typeOfCtaButton: .capsule(buttonTitle: PassColor.textInvert,
                                            buttonBackground: PassColor.aliasInteractionNormMajor1))
        }
    }

    var isInvite: Bool {
        if case .invite = self { return true }
        return false
    }

    var isSlSync: Bool {
        if case .slSync = self { return true }
        return false
    }
}

enum CtaButtonType {
    case text
    case capsule(buttonTitle: UIColor, buttonBackground: UIColor)
}

struct InfoBannerDetail {
    let title: String
    let description: String
    let icon: UIImage?
    /// Call-to-action button title
    let ctaTitle: String?
    let backgroundColor: Color
    let foregroundColor: Color
    let closeButtonColor: Color
    let typeOfCtaButton: CtaButtonType

    init(title: String,
         description: String,
         icon: UIImage?,
         ctaTitle: String?,
         backgroundColor: Color,
         foregroundColor: Color,
         closeButtonColor: Color = PassColor.textInvert.toColor,
         typeOfCtaButton: CtaButtonType = .text) {
        self.title = title
        self.description = description
        self.icon = icon
        self.ctaTitle = ctaTitle
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.closeButtonColor = closeButtonColor
        self.typeOfCtaButton = typeOfCtaButton
    }
}
