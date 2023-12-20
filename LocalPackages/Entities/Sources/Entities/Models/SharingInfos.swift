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

public enum SharingVaultData: Sendable {
    case existing(Vault)
    case new(VaultProtobuf, ItemContent)
}

public extension SharingVaultData {
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
            vault.shared
        default:
            false
        }
    }

    var shareId: String {
        switch self {
        case let .existing(vault):
            vault.shareId
        case let .new(_, content):
            content.shareId
        }
    }
}

public struct SharingInfos: Sendable, Identifiable {
    public var id: String {
        email
    }

    public let vault: SharingVaultData
    public let email: String
    public let role: ShareRole
    /// No public keys means external user
    public let receiverPublicKeys: [PublicKey]?
    public let itemsNum: Int

    public var vaultName: String {
        vault.name
    }

    public var displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences {
        vault.displayPreferences
    }

    public var shared: Bool {
        vault.shared
    }

    public init(vault: SharingVaultData,
                email: String,
                role: ShareRole,
                receiverPublicKeys: [PublicKey]?,
                itemsNum: Int) {
        self.vault = vault
        self.email = email
        self.role = role
        self.receiverPublicKeys = receiverPublicKeys
        self.itemsNum = itemsNum
    }
}
