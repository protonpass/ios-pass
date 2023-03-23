//
// VaultIcon.swift
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

enum VaultIcon: CaseIterable {
    case icon1, icon2, icon3, icon4, icon5, icon6, icon7, icon8, icon9, icon10
    case icon11, icon12, icon13, icon14, icon15, icon16, icon17, icon18, icon19, icon20
    case icon21, icon22, icon23, icon24, icon25, icon26, icon27, icon28, icon29, icon30

    var image: UIImage {
        switch self {
        case .icon1: return PassIcon.vaultIcon1
        case .icon2: return PassIcon.vaultIcon2
        case .icon3: return PassIcon.vaultIcon3
        case .icon4: return PassIcon.vaultIcon4
        case .icon5: return PassIcon.vaultIcon5
        case .icon6: return PassIcon.vaultIcon6
        case .icon7: return PassIcon.vaultIcon7
        case .icon8: return PassIcon.vaultIcon8
        case .icon9: return PassIcon.vaultIcon9
        case .icon10: return PassIcon.vaultIcon10
        case .icon11: return PassIcon.vaultIcon11
        case .icon12: return PassIcon.vaultIcon12
        case .icon13: return PassIcon.vaultIcon13
        case .icon14: return PassIcon.vaultIcon14
        case .icon15: return PassIcon.vaultIcon15
        case .icon16: return PassIcon.vaultIcon16
        case .icon17: return PassIcon.vaultIcon17
        case .icon18: return PassIcon.vaultIcon18
        case .icon19: return PassIcon.vaultIcon19
        case .icon20: return PassIcon.vaultIcon20
        case .icon21: return PassIcon.vaultIcon21
        case .icon22: return PassIcon.vaultIcon22
        case .icon23: return PassIcon.vaultIcon23
        case .icon24: return PassIcon.vaultIcon24
        case .icon25: return PassIcon.vaultIcon25
        case .icon26: return PassIcon.vaultIcon26
        case .icon27: return PassIcon.vaultIcon27
        case .icon28: return PassIcon.vaultIcon28
        case .icon29: return PassIcon.vaultIcon29
        case .icon30: return PassIcon.vaultIcon30
        }
    }
}

extension ProtonPassVaultV1_VaultIcon {
    var icon: VaultIcon {
        switch self {
        case .icon1: return .icon1
        case .icon2: return .icon2
        case .icon3: return .icon3
        case .icon4: return .icon4
        case .icon5: return .icon5
        case .icon6: return .icon6
        case .icon7: return .icon7
        case .icon8: return .icon8
        case .icon9: return .icon9
        case .icon10: return .icon10
        case .icon11: return .icon11
        case .icon12: return .icon12
        case .icon13: return .icon13
        case .icon14: return .icon14
        case .icon15: return .icon15
        case .icon16: return .icon16
        case .icon17: return .icon17
        case .icon18: return .icon18
        case .icon19: return .icon19
        case .icon20: return .icon20
        case .icon21: return .icon21
        case .icon22: return .icon22
        case .icon23: return .icon23
        case .icon24: return .icon24
        case .icon25: return .icon25
        case .icon26: return .icon26
        case .icon27: return .icon27
        case .icon28: return .icon28
        case .icon29: return .icon29
        case .icon30: return .icon30
        default: return .icon1
        }
    }
}
