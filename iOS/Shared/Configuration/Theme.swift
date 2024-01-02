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

import Macro
import ProtonCoreUIFoundations
import UIKit

public enum Theme: Int, Codable, CustomStringConvertible, CaseIterable, Sendable {
    case light = 0
    case dark = 1
    case matchSystem = 2

    public var description: String {
        switch self {
        case .light:
            #localized("Light")
        case .dark:
            #localized("Dark")
        case .matchSystem:
            #localized("Match system")
        }
    }

    public var icon: UIImage {
        switch self {
        case .light:
            IconProvider.sun
        case .dark:
            IconProvider.moon
        case .matchSystem:
            IconProvider.cogWheel
        }
    }

    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        case .matchSystem:
            .unspecified
        }
    }

    public var inAppTheme: InAppTheme {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        case .matchSystem:
            .matchSystem
        }
    }
}
