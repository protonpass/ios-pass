//
// VaultIcon.swift
// Proton Pass - Created on 06/08/2024.
// Copyright (c) 2024 Proton Technologies AG
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

public enum VaultIcon: CaseIterable {
    case icon1, icon2, icon3, icon4, icon5, icon6, icon7, icon8, icon9, icon10
    case icon11, icon12, icon13, icon14, icon15, icon16, icon17, icon18, icon19, icon20
    case icon21, icon22, icon23, icon24, icon25, icon26, icon27, icon28, icon29, icon30

    public var bigImage: Image {
        switch self {
        case .icon1: PassIcon.vaultIcon1Big
        case .icon2: PassIcon.vaultIcon2Big
        case .icon3: PassIcon.vaultIcon3Big
        case .icon4: PassIcon.vaultIcon4Big
        case .icon5: PassIcon.vaultIcon5Big
        case .icon6: PassIcon.vaultIcon6Big
        case .icon7: PassIcon.vaultIcon7Big
        case .icon8: PassIcon.vaultIcon8Big
        case .icon9: PassIcon.vaultIcon9Big
        case .icon10: PassIcon.vaultIcon10Big
        case .icon11: PassIcon.vaultIcon11Big
        case .icon12: PassIcon.vaultIcon12Big
        case .icon13: PassIcon.vaultIcon13Big
        case .icon14: PassIcon.vaultIcon14Big
        case .icon15: PassIcon.vaultIcon15Big
        case .icon16: PassIcon.vaultIcon16Big
        case .icon17: PassIcon.vaultIcon17Big
        case .icon18: PassIcon.vaultIcon18Big
        case .icon19: PassIcon.vaultIcon19Big
        case .icon20: PassIcon.vaultIcon20Big
        case .icon21: PassIcon.vaultIcon21Big
        case .icon22: PassIcon.vaultIcon22Big
        case .icon23: PassIcon.vaultIcon23Big
        case .icon24: PassIcon.vaultIcon24Big
        case .icon25: PassIcon.vaultIcon25Big
        case .icon26: PassIcon.vaultIcon26Big
        case .icon27: PassIcon.vaultIcon27Big
        case .icon28: PassIcon.vaultIcon28Big
        case .icon29: PassIcon.vaultIcon29Big
        case .icon30: PassIcon.vaultIcon30Big
        }
    }

    public var smallImage: Image {
        switch self {
        case .icon1: PassIcon.vaultIcon1Small
        case .icon2: PassIcon.vaultIcon2Small
        case .icon3: PassIcon.vaultIcon3Small
        case .icon4: PassIcon.vaultIcon4Small
        case .icon5: PassIcon.vaultIcon5Small
        case .icon6: PassIcon.vaultIcon6Small
        case .icon7: PassIcon.vaultIcon7Small
        case .icon8: PassIcon.vaultIcon8Small
        case .icon9: PassIcon.vaultIcon9Small
        case .icon10: PassIcon.vaultIcon10Small
        case .icon11: PassIcon.vaultIcon11Small
        case .icon12: PassIcon.vaultIcon12Small
        case .icon13: PassIcon.vaultIcon13Small
        case .icon14: PassIcon.vaultIcon14Small
        case .icon15: PassIcon.vaultIcon15Small
        case .icon16: PassIcon.vaultIcon16Small
        case .icon17: PassIcon.vaultIcon17Small
        case .icon18: PassIcon.vaultIcon18Small
        case .icon19: PassIcon.vaultIcon19Small
        case .icon20: PassIcon.vaultIcon20Small
        case .icon21: PassIcon.vaultIcon21Small
        case .icon22: PassIcon.vaultIcon22Small
        case .icon23: PassIcon.vaultIcon23Small
        case .icon24: PassIcon.vaultIcon24Small
        case .icon25: PassIcon.vaultIcon25Small
        case .icon26: PassIcon.vaultIcon26Small
        case .icon27: PassIcon.vaultIcon27Small
        case .icon28: PassIcon.vaultIcon28Small
        case .icon29: PassIcon.vaultIcon29Small
        case .icon30: PassIcon.vaultIcon30Small
        }
    }
}

public extension ProtonPassVaultV1_VaultIcon {
    var icon: VaultIcon {
        switch self {
        case .icon1: .icon1
        case .icon2: .icon2
        case .icon3: .icon3
        case .icon4: .icon4
        case .icon5: .icon5
        case .icon6: .icon6
        case .icon7: .icon7
        case .icon8: .icon8
        case .icon9: .icon9
        case .icon10: .icon10
        case .icon11: .icon11
        case .icon12: .icon12
        case .icon13: .icon13
        case .icon14: .icon14
        case .icon15: .icon15
        case .icon16: .icon16
        case .icon17: .icon17
        case .icon18: .icon18
        case .icon19: .icon19
        case .icon20: .icon20
        case .icon21: .icon21
        case .icon22: .icon22
        case .icon23: .icon23
        case .icon24: .icon24
        case .icon25: .icon25
        case .icon26: .icon26
        case .icon27: .icon27
        case .icon28: .icon28
        case .icon29: .icon29
        case .icon30: .icon30
        default: .icon1
        }
    }
}
