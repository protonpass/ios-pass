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

public enum SharingElementData: Sendable {
    case vault(Vault)
    case item(item: ItemContent, share: Share)
    case new(VaultContent, ItemContent)
}

public extension ShareElementProtocol {
    var displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences? {
        if let vault = self as? Vault {
            vault.displayPreferences
        } else {
            nil
        }
    }
}

public extension SharingElementData {
    var name: String {
        switch self {
        case let .vault(vault):
            vault.name
        case let .item(item, _):
            item.name
        case let .new(vault, _):
            vault.name
        }
    }

    var displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences? {
        switch self {
        case let .vault(vault):
            vault.displayPreferences
        case let .new(vault, _):
            vault.display
        default:
            nil
        }
    }

    var shared: Bool {
        switch self {
        case let .vault(vault):
            vault.shared
        case let .item(_, share):
            share.shared
        default:
            false
        }
    }

    var shareId: String {
        switch self {
        case let .vault(vault):
            vault.shareId
        case let .item(_, share):
            share.id
        case let .new(_, content):
            content.shareId
        }
    }
}

public struct SharingInfos: Sendable, Identifiable {
    public var id: String {
        email
    }

    public let shareElement: SharingElementData
    public let email: String
    public let role: ShareRole
    /// No public keys means external user
    public let receiverPublicKeys: [PublicKey]?
    public let itemsNum: Int
    public var name: String {
        shareElement.name
    }

    public var displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences? {
        shareElement.displayPreferences
    }

    public var shared: Bool {
        shareElement.shared
    }

    public var isItem: Bool {
        if case .item = shareElement {
            return true
        }
        return false
    }

    public init(shareElement: SharingElementData,
                email: String,
                role: ShareRole,
                receiverPublicKeys: [PublicKey]?,
                itemsNum: Int) {
        self.shareElement = shareElement
        self.email = email
        self.role = role
        self.receiverPublicKeys = receiverPublicKeys
        self.itemsNum = itemsNum
    }
}
