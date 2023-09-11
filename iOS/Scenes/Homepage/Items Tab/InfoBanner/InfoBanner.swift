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
import SwiftUI

enum InfoBanner: CaseIterable, Equatable, Hashable {
    static var allCases: [InfoBanner] {
        [.trial, .autofill, .aliases]
    }

    case trial, autofill, aliases, invite([UserInvite])

    var id: String {
        switch self {
        case .trial:
            return "trial"
        case .autofill:
            return "autofill"
        case .aliases:
            return "aliases"
        case .invite:
            return "invite"
        }
    }

    // swiftlint:disable line_length
    var detail: InfoBannerDetail {
        switch self {
        case .trial:
            return .init(title: "Enjoy your free trial".localized,
                         description: "Check out all the exclusive features that are available to you for a limited time"
                             .localized,
                         icon: nil,
                         ctaTitle: "Learn more".localized,
                         backgroundColor: PassColor.noteInteractionNormMajor1.toColor,
                         foregroundColor: PassColor.textInvert.toColor)
        case .autofill:
            return .init(title: "Enjoy the magic of AutoFill".localized,
                         description: "One tap and⏤presto!⏤your username and password are filled in instantly"
                             .localized,
                         icon: PassIcon.infoBannerAutoFill,
                         ctaTitle: "Turn on AutoFill".localized,
                         backgroundColor: PassColor.aliasInteractionNormMajor1.toColor,
                         foregroundColor: PassColor.textInvert.toColor)

        case .aliases:
            return .init(title: "Use email aliases".localized,
                         description: "Protect your inbox against spams and phishings".localized,
                         icon: PassIcon.infoBannerAliases,
                         ctaTitle: nil,
                         backgroundColor: PassColor.signalSuccess.toColor,
                         foregroundColor: PassColor.textInvert.toColor)
        case .invite:
            return .init(title: "Shared vault invitation".localized,
                         description: "You've been invited to a vault. Tap here to see the invitation.".localized,
                         icon: PassIcon.inviteBannerIcon,
                         ctaTitle: nil,
                         backgroundColor: PassColor.backgroundMedium.toColor,
                         foregroundColor: PassColor.textNorm.toColor)
        }
    }

    // swiftlint:enable line_length

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
