//
// ItemRevision.swift
// Proton Pass - Created on 13/08/2022.
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

import Core
import CryptoKit
import Entities
import ProtonCoreDataModel
import ProtonCoreLogin

public struct ItemRevisionsPaginated: Decodable {
    public let total: Int
    public let lastToken: String?
    public let revisionsData: [ItemRevision]
}

public struct ItemRevision: Decodable, Equatable, Sendable, Hashable {
    public let itemID: String
    public let revision: Int64
    public let contentFormatVersion: Int64
    public let keyRotation: Int64
    public let content: String

    /// Base64 encoded item key. Only for vault shares.
    public let itemKey: String?

    /// Revision state. Values: 1 = Active, 2 = Trashed
    public let state: Int64

    /// In case this item contains an alias, this is the email address for the alias
    public let aliasEmail: String?

    /// Creation time of the item
    public let createTime: Int64

    /// Time of last update of the item
    public let modifyTime: Int64

    /// Time when the item was last used
    public let lastUseTime: Int64?

    /// Creation time of this revision
    public let revisionTime: Int64

    /// Enum representation of `state`
    public var itemState: ItemState { .init(rawValue: state) ?? .active }
}

public extension ItemRevision {
    func getContentProtobuf(vaultKey: DecryptedShareKey) throws -> ItemContentProtobuf {
        guard vaultKey.keyRotation == keyRotation else {
            throw PassError.crypto(.unmatchedKeyRotation(lhsKey: vaultKey.keyRotation,
                                                         rhsKey: keyRotation))
        }

        #warning("Handle this")
        guard let itemKey else {
            throw PassError.crypto(.failedToDecryptContent)
        }

        guard let itemKeyData = try itemKey.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedItemKeyData = try AES.GCM.open(itemKeyData,
                                                    key: vaultKey.keyData,
                                                    associatedData: .itemKey)

        guard let contentData = try content.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptedContentData = try AES.GCM.open(contentData,
                                                    key: decryptedItemKeyData,
                                                    associatedData: .itemContent)

        return try ItemContentProtobuf(data: decryptedContentData)
    }
}
