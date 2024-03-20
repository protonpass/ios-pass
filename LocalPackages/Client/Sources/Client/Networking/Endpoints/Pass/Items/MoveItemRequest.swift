//
// MoveItemRequest.swift
// Proton Pass - Created on 29/03/2023.
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

import Core
import CryptoKit
import Entities
import Foundation

public struct MoveItemRequest: Sendable {
    /// Encrypted ID of the destination share
    public let shareId: String
    public let item: ItemToBeMoved
    public let history: [ItemHistoryToBeMoved]?
}

public struct ItemHistoryToBeMoved: Decodable, Sendable {
    public let revision: Int
    public let item: ItemToBeMoved
}

extension ItemHistoryToBeMoved: Encodable {
    enum CodingKeys: String, CodingKey {
        case revision = "Revision"
        case item = "Item"
    }
}

public struct ItemToBeMoved: Decodable, Sendable {
    /// Encrypted ID of the VaultKey used to create this item
    /// >= 1
    public let keyRotation: Int64

    /// Version of the content format used to create the item
    /// >= 1
    public let contentFormatVersion: Int

    /// Encrypted item content encoded in Base64
    public let content: String

    /// Item key encrypted with the VaultKey, contents encoded in base64
    public let itemKey: String
}

extension MoveItemRequest {
    init(itemContent: any ProtobufableItemContentProtocol,
         destinationShareId: String,
         destinationShareKey: DecryptedShareKey,
         itemHistory: [ItemHistory]) throws {
        let itemKey = try Data.random()
        let encryptedContent = try AES.GCM.seal(itemContent.data(),
                                                key: itemKey,
                                                associatedData: .itemContent)

        guard let content = encryptedContent.combined?.base64EncodedString() else {
            throw PassError.crypto(.failedToAESEncrypt)
        }

        let encryptedItemKey = try AES.GCM.seal(itemKey,
                                                key: destinationShareKey.keyData,
                                                associatedData: .itemKey)
        let encryptedItemKeyData = encryptedItemKey.combined ?? .init()

        var historyToBeMoved: [ItemHistoryToBeMoved]?
        if !itemHistory.isEmpty {
            historyToBeMoved = try itemHistory
                .map { try $0.toItemHistoryToBeMoved(destinationShareKey: destinationShareKey) }
        }

        self.init(shareId: destinationShareId,
                  item: ItemToBeMoved(keyRotation: destinationShareKey.keyRotation,
                                      contentFormatVersion: Constants.ContentFormatVersion.item,
                                      content: content,
                                      itemKey: encryptedItemKeyData.base64EncodedString()),
                  history: historyToBeMoved)
    }
}

extension ItemContent {
    func toItemToBeMoved(destinationShareKey: DecryptedShareKey) throws -> ItemToBeMoved {
        let itemKey = try Data.random()
        let encryptedContent = try AES.GCM.seal(protobuf.data(),
                                                key: itemKey,
                                                associatedData: .itemContent)

        guard let content = encryptedContent.combined?.base64EncodedString() else {
            throw PassError.crypto(.failedToAESEncrypt)
        }

        let encryptedItemKey = try AES.GCM.seal(itemKey,
                                                key: destinationShareKey.keyData,
                                                associatedData: .itemKey)
        let encryptedItemKeyData = encryptedItemKey.combined ?? .init()

        return ItemToBeMoved(keyRotation: destinationShareKey.keyRotation,
                             contentFormatVersion: Constants.ContentFormatVersion.item,
                             content: content,
                             itemKey: encryptedItemKeyData.base64EncodedString())
    }
}

extension ItemHistory {
    func toItemHistoryToBeMoved(destinationShareKey: DecryptedShareKey) throws -> ItemHistoryToBeMoved {
        try ItemHistoryToBeMoved(revision: revision,
                                 item: itemContent.toItemToBeMoved(destinationShareKey: destinationShareKey))
    }
}

extension ItemToBeMoved: Encodable {
    enum CodingKeys: String, CodingKey {
        case keyRotation = "KeyRotation"
        case contentFormatVersion = "ContentFormatVersion"
        case content = "Content"
        case itemKey = "ItemKey"
    }
}

extension MoveItemRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case shareId = "ShareID"
        case item = "Item"
        case history = "History"
    }
}
