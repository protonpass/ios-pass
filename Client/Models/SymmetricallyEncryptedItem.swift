//
// SymmetricallyEncryptedItem.swift
// Proton Pass - Created on 12/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import CryptoKit

public enum SymmetricallyEncryptedItemError: Error {
    case corruptedEncryptedContent
}

/// ItemRevision with its symmetrically encrypted content by an application-wide symmetric key
public struct SymmetricallyEncryptedItem {
    /// ID of the share that the item belongs to
    public let shareId: String

    /// Original item revision object as returned by the server
    public let item: ItemRevision

    /// Symmetrically encrypted content in base 64 format
    public let encryptedContent: String

    /// Time interval since 1970 of the moment when the item is last used
    public let lastUsedTime: Int64

    /// Whether the item is type log in or not
    public let isLogInItem: Bool

    public func getEncryptedItemContent() throws -> ItemContent {
        guard let data = try encryptedContent.base64Decode() else {
            throw SymmetricallyEncryptedItemError.corruptedEncryptedContent
        }
        let protobufItem = try ItemContentProtobuf(data: data)
        return .init(shareId: shareId,
                     itemId: item.itemID,
                     contentProtobuf: protobufItem)
    }

    public func getDecryptedItemContent(symmetricKey: SymmetricKey) throws -> ItemContent {
        guard let data = try encryptedContent.base64Decode() else {
            throw SymmetricallyEncryptedItemError.corruptedEncryptedContent
        }
        let encryptedProtobufItem = try ItemContentProtobuf(data: data)
        let decryptedProtobufItem = try encryptedProtobufItem.symmetricallyDecrypted(symmetricKey)
        return .init(shareId: shareId,
                     itemId: item.itemID,
                     contentProtobuf: decryptedProtobufItem)
    }
}

// https://sarunw.com/posts/how-to-sort-by-multiple-properties-in-swift/
private typealias AreInDecreasingOrder = (SymmetricallyEncryptedItem,
                                          SymmetricallyEncryptedItem) -> Bool

extension Array where Element == SymmetricallyEncryptedItem {
    // swiftlint:disable opening_brace
    /// Sort by `lastUsedTime` & `modifyTime` in decreasing order
    func sorted() -> Self {
        let predicates: [AreInDecreasingOrder] =
        [
            { $0.lastUsedTime > $1.lastUsedTime },
            { $0.item.modifyTime > $1.item.modifyTime }
        ]
        return sorted { lhs, rhs in
            for predicate in predicates {
                if !predicate(lhs, rhs) && !predicate(rhs, lhs) {
                    continue
                }

                return predicate(lhs, rhs)
            }
            return false
        }
    }
}
