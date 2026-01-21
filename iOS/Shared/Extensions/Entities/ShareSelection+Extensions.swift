//
// ShareSelection+Extensions.swift
// Proton Pass - Created on 15/01/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Macro
import ProtonCoreUIFoundations
import SwiftUI

extension ShareSelection {
    var title: String {
        switch self {
        case .all:
            #localized("All items")
        case let .precise(selection):
            selection.title
        case .trash:
            #localized("Trash")
        case .sharedByMe:
            #localized("Shared by me")
        case .sharedWithMe:
            #localized("Shared with me")
        }
    }

    var icon: Image {
        switch self {
        case .all:
            PassIcon.brandPass
        case let .precise(selection):
            selection.share.vaultBigIcon ?? PassIcon.vaultIcon1Big
        case .trash:
            IconProvider.trash
        case .sharedByMe:
            IconProvider.userArrowRight
        case .sharedWithMe:
            IconProvider.userArrowLeft
        }
    }

    var color: Color {
        switch self {
        case .all, .sharedByMe, .sharedWithMe:
            PassColor.interactionNormMajor2
        case let .precise(selection):
            selection.share.mainColor ?? PassColor.textWeak
        case .trash:
            PassColor.textWeak
        }
    }

    var share: Share? {
        switch self {
        case let .precise(selection):
            selection.share
        default:
            nil
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .all:
            #localized("Show all vaults")
        case let .precise(selection):
            #localized("Show %@ %@", selection.title, selection.isFolderSelected ? "folder" : "vault")
        case .trash:
            #localized("Show trash")
        case .sharedByMe:
            #localized("Show shared by me")
        case .sharedWithMe:
            #localized("Show shared with me")
        }
    }
}
