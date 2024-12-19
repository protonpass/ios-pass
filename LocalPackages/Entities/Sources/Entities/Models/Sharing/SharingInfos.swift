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
    case vault(Share)
    case item(item: ItemContent, share: Share)
    case new(VaultContent, ItemContent)
}

public extension SharingElementData {
    var name: String {
        switch self {
        case let .vault(share):
            share.vaultName ?? ""
        case let .item(item, _):
            item.name
        case let .new(vault, _):
            vault.name
        }
    }

    var shared: Bool {
        switch self {
        case let .vault(share):
            share.shared
        case let .item(_, share):
            share.shared
        default:
            false
        }
    }

    var shareId: String {
        switch self {
        case let .vault(share):
            share.id
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

    public var shared: Bool {
        shareElement.shared
    }

    public var shareTargetType: TargetType {
        if case .item = shareElement {
            return .item
        }
        return .vault
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
