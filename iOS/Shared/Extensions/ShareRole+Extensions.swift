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

extension ShareRole {
    var role: String {
        switch self {
        case .admin:
            "admin".localized
        case .write:
            "edit".localized
        case .read:
            "read".localized
        }
    }

    var title: String {
        switch self {
        case .read:
            "Can View".localized
        case .write:
            "Can Edit".localized
        case .admin:
            "Can Manage".localized
        }
    }

    var description: String {
        switch self {
        case .read:
            "Can view items in this vault".localized
        case .write:
            "Can create, edit, delete and export items in this vault".localized
        case .admin:
            "Can grant and revoke access to this vault".localized
        }
    }

    var summary: String {
        switch self {
        case .read:
            "only view items".localized
        case .write:
            "create, edit, delete and export items".localized
        case .admin:
            "grant and revoke access".localized
        }
    }
}
