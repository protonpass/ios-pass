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
import GoLibs
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_KeyManager
import ProtonCore_Login

public enum ItemState: Int16, CaseIterable {
    case active = 1
    case trashed = 2

    public var description: String {
        switch self {
        case .active:
            return "active"
        case .trashed:
            return "trashed"
        }
    }
}

public struct ItemRevisionList: Decodable {
    public let total: Int
    public let revisionsData: [ItemRevision]
}

public struct ItemRevision: Decodable, Equatable {
    public let itemID: String
    public let revision: Int64
    public let contentFormatVersion: Int16
    public let keyRotation: Int64
    public let content: String

    /// Base64 encoded item key. Only for vault shares.
    public let itemKey: String?

    /// Revision state. Values: 1 = Active, 2 = Trashed
    public let state: Int16

    /// In case this item contains an alias, this is the email address for the alias
    public let aliasEmail: String?

    /// Creation time of the item
    public let createTime: Int64

    /// Time of last update of the item
    public let modifyTime: Int64

    /// Time when the item was last used
    public let lastUseTime: Int64

    /// Creation time of this revision
    public let revisionTime: Int64

    /// Enum representation of `state`
    public var itemState: ItemState { .init(rawValue: state) ?? .active }
}

extension ItemRevision {
    public func getContentProtobuf(userData: UserData,
                                   share: Share,
                                   shareKeys: [ShareKey]) throws -> ItemContentProtobuf {
        try ItemContentProtobuf(data: Data())
    }

    private func decryptField(decryptionKeys: [DecryptionKey], field: String) throws -> Data {
        guard let decoded = try field.base64Decode() else {
            throw PPClientError.crypto(.failedToDecode)
        }
        let armoredDecoded = try CryptoUtils.armorMessage(decoded)
        return try ProtonCore_Crypto.Decryptor.decrypt(decryptionKeys: decryptionKeys,
                                                       encrypted: .init(value: armoredDecoded))
    }
}
