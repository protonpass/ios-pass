//
// ShareRole+Extensions.swift
// Proton Pass - Created on 27/07/2023.
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

extension ShareRole {
    var title: String {
        switch self {
        case .read:
            #localized("Viewer")
        case .write:
            #localized("Editor")
        case .admin:
            #localized("Admin")
        }
    }

    func description(isItemSharing: Bool = false) -> String {
        switch self {
        case .read:
            isItemSharing ? #localized("Can view this item") : #localized("Can view items in this vault")
        case .write:
            isItemSharing ? #localized("Can edit and delete this item.") :
                #localized("Can create, edit, delete and export items in this vault")
        case .admin:
            isItemSharing ? #localized("Can grant and revoke access to the item.") :
                #localized("Can grant and revoke access to this vault")
        }
    }
}
