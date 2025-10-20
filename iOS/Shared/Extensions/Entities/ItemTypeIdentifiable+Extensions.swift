//
// ItemTypeIdentifiable+Extensions.swift
// Proton Pass - Created on 24/11/2023.
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

extension ItemTypeIdentifiable {
    var trashMessage: String {
        switch type {
        case .login:
            #localized("Login moved to trash")
        case .alias:
            #localized("Alias \"%@\" moved to trash", aliasEmail ?? "")
        case .creditCard:
            #localized("Credit card moved to trash")
        case .note:
            #localized("Note moved to trash")
        case .identity:
            #localized("Identity moved to trash")
        case .sshKey:
            #localized("SSH key moved to trash")
        case .wifi:
            #localized("WiFi network moved to trash")
        case .custom:
            #localized("Custom item moved to trash")
        }
    }
}
