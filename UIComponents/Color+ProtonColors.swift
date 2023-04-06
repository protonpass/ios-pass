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
}
