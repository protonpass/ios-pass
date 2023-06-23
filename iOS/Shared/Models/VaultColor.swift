//
// VaultColor.swift
// Proton Pass - Created on 23/03/2023.
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
import UIComponents
import UIKit

enum VaultColor: CaseIterable {
    case color1, color2, color3, color4, color5, color6, color7, color8, color9, color10

    var color: UIColor {
        switch self {
        case .color1: return PassColor.vaultHeliotrope
        case .color2: return PassColor.vaultMauvelous
        case .color3: return PassColor.vaultMarigoldYellow
        case .color4: return PassColor.vaultDeYork
        case .color5: return PassColor.vaultJordyBlue
        case .color6: return PassColor.vaultLavenderMagenta
        case .color7: return PassColor.vaultChestnutRose
        case .color8: return PassColor.vaultPorsche
        case .color9: return PassColor.vaultMercury
        case .color10: return PassColor.vaultWaterLeaf
        }
    }
}

extension ProtonPassVaultV1_VaultColor {
    var color: VaultColor {
        switch self {
        case .color1: return .color1
        case .color2: return .color2
        case .color3: return .color3
        case .color4: return .color4
        case .color5: return .color5
        case .color6: return .color6
        case .color7: return .color7
        case .color8: return .color8
        case .color9: return .color9
        case .color10: return .color10
        default: return .color1
        }
    }
}
