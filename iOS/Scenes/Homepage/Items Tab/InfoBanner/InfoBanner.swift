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

import UIComponents
import UIKit

enum InfoBanner: String, CaseIterable {
    // Order of cases matter cause it affects the UI
    case trial, autofill, aliases

    var id: String { rawValue }

    var detail: InfoBannerDetail {
        switch self {
        case .trial:
            // swiftlint:disable line_length
            return .init(title: "Enjoy your free trial",
                         description: "Check out all the exclusive features that are available to you for a limited time.",
                         icon: nil,
                         ctaTitle: "Learn more",
                         backgroundColor: PassColor.noteInteractionNormMajor1)
            // swiftlint:enable line_length
        case .autofill:
            return .init(title: "Enjoy the magic of AutoFill",
                         description: "One tap and⏤presto!⏤your username and password are filled in instantly.",
                         icon: PassIcon.infoBannerAutoFill,
                         ctaTitle: "Turn on AutoFill",
                         backgroundColor: PassColor.aliasInteractionNormMajor1)

        case .aliases:
            return .init(title: "Use email aliases",
                         description: "Protect your inbox against spams and phishings.",
                         icon: PassIcon.infoBannerAliases,
                         ctaTitle: nil,
                         backgroundColor: PassColor.signalSuccess)
        }
    }
}

struct InfoBannerDetail {
    let title: String
    let description: String
    let icon: UIImage?
    /// Call-to-action button title
    let ctaTitle: String?
    let backgroundColor: UIColor
}
