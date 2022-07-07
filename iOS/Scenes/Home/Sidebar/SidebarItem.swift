//
// SidebarItem.swift
// Proton Pass - Created on 06/07/2022.
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
import UIKit

enum SidebarItem {
    case myVaults, settings, trash, help, signOut

    var title: String {
        switch self {
        case .myVaults:
            return "My vaults"
        case .settings:
            return "Settings"
        case .trash:
            return "Trash"
        case .help:
            return "Help"
        case .signOut:
            return "Sign out"
        }
    }

    var icon: UIImage {
        switch self {
        case .myVaults:
            return IconProvider.filingCabinet
        case .settings:
            return IconProvider.cogWheel
        case .trash:
            return IconProvider.trash
        case .help:
            return IconProvider.questionCircle
        case .signOut:
            return IconProvider.arrowOutFromRectangle
        }
    }
}
