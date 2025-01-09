//
// VaultSelection+Extension.swift
// Proton Pass - Created on 07/12/2023.
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

import Entities
import Macro

public extension VaultSelection {
    var searchBarPlaceholder: String {
        switch self {
        case .all:
            #localized("Search in all items...", bundle: .module)
        case let .precise(share):
            #localized("Search in %@...", bundle: .module, share.vaultContent?.name ?? "")
        case .trash:
            #localized("Search in Trash...", bundle: .module)
        case .sharedByMe:
            #localized("Search in items shared by me", bundle: .module)
        case .sharedWithMe:
            #localized("Search in items shared with me", bundle: .module)
        }
    }
}
