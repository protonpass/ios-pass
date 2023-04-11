//
// ItemContent+UIRelatedProperties.swift
// Proton Pass - Created on 08/02/2023.
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

import Client
import ProtonCore_UIFoundations
import UIComponents
import UIKit

extension ItemContentType {
    var icon: UIImage {
        switch self {
        case .alias:
            return IconProvider.alias
        case .login:
            return IconProvider.keySkeleton
        case .note:
            return IconProvider.notepadChecklist
        }
    }

    var tintColor: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNormMajor1
        case .login:
            return PassColor.loginInteractionNormMajor1
        case .note:
            return PassColor.noteInteractionNormMajor1
        }
    }

    var iconTintColor: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNormMajor2
        case .login:
            return PassColor.loginInteractionNormMajor2
        case .note:
            return PassColor.noteInteractionNormMajor2
        }
    }

    var backgroundNormColor: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNormMinor1
        case .login:
            return PassColor.loginInteractionNormMinor1
        case .note:
            return PassColor.noteInteractionNormMinor1
        }
    }

    var backgroundWeakColor: UIColor {
        switch self {
        case .alias:
            return PassColor.aliasInteractionNormMinor2
        case .login:
            return PassColor.loginInteractionNormMinor2
        case .note:
            return PassColor.noteInteractionNormMinor2
        }
    }
}
