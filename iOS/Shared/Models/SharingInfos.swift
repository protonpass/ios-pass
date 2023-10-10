//
// SharingInfos.swift
// Proton Pass - Created on 24/07/2023.
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
import Entities
import Macro

enum SharingVault {
    case existing(Vault)
    case new(VaultProtobuf, ItemContent)
}

extension SharingVault {
    var name: String {
        switch self {
        case let .existing(vault):
            vault.name
        case let .new(vault, _):
            vault.name
        }
    }

    var displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences {
        switch self {
        case let .existing(vault):
            vault.displayPreferences
        case let .new(vault, _):
            vault.display
        }
    }

    var shared: Bool {
        switch self {
        case let .existing(vault):
            vault.isShared
        default:
            false
        }
    }
}

extension VaultProtobuf {
    static var defaultNewSharedVault: Self {
        var vault = VaultProtobuf()
        vault.name = #localized("Shared vault")
        vault.display.color = .color3
        vault.display.icon = .icon9
        return vault
    }
}

struct SharingInfos {
    let vault: SharingVault?
    let email: String?
    let role: ShareRole?
    let receiverPublicKeys: [PublicKey]?
    let itemsNum: Int?

    var vaultName: String? {
        vault?.name
    }

    var displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences {
        vault?.displayPreferences ?? .init()
    }

    var shared: Bool {
        vault?.shared ?? false
    }
}
