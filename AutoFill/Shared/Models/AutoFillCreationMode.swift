//
// AutoFillCreationMode.swift
// Proton Pass - Created on 03/09/2024.
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

import Entities
import Foundation

enum AutoFillCreationMode {
    case login(userId: String, [Vault], URL?, PasskeyCredentialRequest?)
    case alias(userId: String, [Vault])

    var vaults: [Vault] {
        switch self {
        case let .login(_, vaults, _, _):
            vaults
        case let .alias(_, vaults):
            vaults
        }
    }

    var userId: String {
        switch self {
        case let .login(userId, _, _, _):
            userId
        case let .alias(userId, _):
            userId
        }
    }
}
