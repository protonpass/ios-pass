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

// swiftlint:disable line_length
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
            return .init(title: #localized("Our welcome gift to you"),
                         description: #localized("7 days to try premium features for free. Only during your first week of Proton Pass."),
                         icon: nil,
                         ctaTitle: #localized("Learn more"),
                         backgroundColor: PassColor.noteInteractionNormMajor1.toColor,
                         foregroundColor: PassColor.textInvert.toColor)
        case .autofill:
            return .init(title: #localized("Enjoy the magic of AutoFill"),
                         description: #localized("One tap and⏤presto!⏤your username and password are filled in instantly"),
                         icon: PassIcon.infoBannerAutoFill,
                         ctaTitle: #localized("Turn on AutoFill"),
                         backgroundColor: PassColor.aliasInteractionNormMajor1.toColor,
                         foregroundColor: PassColor.textInvert.toColor)
        case .aliases:
            return .init(title: #localized("Goodbye spam and scams"),
                         description: #localized("Use email aliases to protect your inbox and identity"),
                         icon: PassIcon.infoBannerAliases,
                         ctaTitle: #localized("Learn more"),
                         backgroundColor: PassColor.signalSuccess.toColor,
                         foregroundColor: PassColor.textInvert.toColor)
        case let .invite(userInvites):
            var title = #localized("Vault shared with you")
            var description = #localized("You're invited to a shared vault. Tap for details.")

            if let invite = userInvites.first, invite.inviteType == .item {
                title = #localized("%@ wants to share an item with you.", invite.inviterEmail)
                description = #localized("Tap here for details")
            }
            return .init(title: title,
                         description: description,
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

// swiftlint:enable line_length

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
