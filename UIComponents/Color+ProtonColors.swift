//
// Color+ProtonColors.swift
// Proton Pass - Created on 15/11/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_UIFoundations
import SwiftUI

// MARK: - UIColor for core colors
public extension UIColor {
    static var backgroundSecondary: UIColor {
        ColorProvider.BackgroundSecondary
    }

    static var brandNorm: UIColor {
        ColorProvider.BrandNorm
    }

    static var iconHint: UIColor {
        ColorProvider.IconHint
    }

    static var iconWeak: UIColor {
        ColorProvider.IconWeak
    }

    static var interactionNorm: UIColor {
        ColorProvider.InteractionNorm
    }

    static var interactionNormPressed: UIColor {
        ColorProvider.InteractionNormPressed
    }

    static var interactionWeak: UIColor {
        ColorProvider.InteractionWeak
    }

    static var notificationError: UIColor {
        ColorProvider.NotificationError
    }

    static var notificationSuccess: UIColor {
        ColorProvider.NotificationSuccess
    }

    static var notificationWarning: UIColor {
        ColorProvider.NotificationWarning
    }

    static var separatorNorm: UIColor {
        ColorProvider.SeparatorNorm
    }

    static var sidebarBackground: UIColor {
        ColorProvider.SidebarBackground
    }

    static var sidebarIconWeak: UIColor {
        ColorProvider.SidebarIconWeak
    }

    static var sidebarInteractionPressed: UIColor {
        ColorProvider.SidebarInteractionPressed
    }

    static var sidebarInteractionWeakNorm: UIColor {
        ColorProvider.SidebarInteractionWeakNorm
    }

    static var sidebarSeparator: UIColor {
        ColorProvider.SidebarSeparator
    }

    static var sidebarTextNorm: UIColor {
        ColorProvider.SidebarTextNorm
    }

    static var sidebarTextWeak: UIColor {
        ColorProvider.SidebarTextWeak
    }

    static var textDisabled: UIColor {
        ColorProvider.TextDisabled
    }

    static var textNorm: UIColor {
        ColorProvider.TextNorm
    }

    static var textWeak: UIColor {
        ColorProvider.TextWeak
    }
}

// MARK: - Color for core colors
public extension Color {
    static var backgroundSecondary: Color {
        .init(uiColor: .backgroundSecondary)
    }

    static var brandNorm: Color {
        .init(uiColor: .brandNorm)
    }

    static var iconHint: Color {
        .init(uiColor: .iconHint)
    }

    static var iconWeak: Color {
        .init(uiColor: .iconWeak)
    }

    static var interactionNorm: Color {
        .init(uiColor: .interactionNorm)
    }

    static var interactionNormPressed: Color {
        .init(uiColor: .interactionNormPressed)
    }

    static var interactionWeak: Color {
        .init(uiColor: .interactionWeak)
    }

    static var notificationError: Color {
        .init(uiColor: .notificationError)
    }

    static var notificationSuccess: Color {
        .init(uiColor: .notificationSuccess)
    }

    static var notificationWarning: Color {
        .init(uiColor: .notificationWarning)
    }

    static var separatorNorm: Color {
        .init(uiColor: .separatorNorm)
    }

    static var sidebarBackground: Color {
        .init(uiColor: .sidebarBackground)
    }

    static var sidebarIconWeak: Color {
        .init(uiColor: .sidebarIconWeak)
    }

    static var sidebarInteractionPressed: Color {
        .init(uiColor: .sidebarInteractionPressed)
    }

    static var sidebarInteractionWeakNorm: Color {
        .init(uiColor: .sidebarInteractionWeakNorm)
    }

    static var sidebarSeparator: Color {
        .init(uiColor: .sidebarSeparator)
    }

    static var sidebarTextNorm: Color {
        .init(uiColor: .sidebarTextNorm)
    }

    static var sidebarTextWeak: Color {
        .init(uiColor: .sidebarTextWeak)
    }

    static var textDisabled: Color {
        .init(uiColor: .textDisabled)
    }

    static var textNorm: Color {
        .init(uiColor: .textNorm)
    }

    static var textWeak: Color {
        .init(uiColor: .textWeak)
    }
}

// MARK: - UIColor for Pass specific colors
public extension UIColor {
    static var passBackground: UIColor {
        .init(red: 25, green: 25, blue: 39)
    }

    static var passBrand: UIColor {
        .init(red: 167, green: 121, blue: 255)
    }
}

// MARK: - Color for Pass specific colors
public extension Color {
    static var passBackground: Color {
        .init(uiColor: .passBackground)
    }

    static var passBrand: Color {
        .init(uiColor: .passBrand)
    }
}
