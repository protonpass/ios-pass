//
// Theme.swift
// Proton Pass - Created on 21/12/2022.
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

public enum Theme: Int, CustomStringConvertible, CaseIterable {
    case light = 0
    case dark = 1
    case matchSystem = 2

    public var description: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .matchSystem:
            return "Match system"
        }
    }

    public var icon: UIImage {
        switch self {
        case .light:
            return IconProvider.sun
        case .dark:
            return IconProvider.moon
        case .matchSystem:
            return IconProvider.cogWheel
        }
    }

    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .matchSystem:
            return .unspecified
        }
    }
    
    public var inAppTheme: InAppTheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .matchSystem:
            return .matchSystem
        }
    }
}
