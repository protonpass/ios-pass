//
// ItemContentProtocol.swift
// Proton Pass - Created on 09/08/2022.
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

public enum ItemContentType: Int, CaseIterable {
    case login = 0
    case alias = 1
    case note = 2

    public var creationMessage: String {
        switch self {
        case .login:
            return "Login created"
        case .alias:
            return "Alias created"
        case .note:
            return "Note created"
        }
    }
}

extension ItemContentType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .login: return "login"
        case .alias: return "alias"
        case .note: return "note"
        }
    }
}

public enum ItemContentData {
    case alias
    case login(LogInItemData)
    case note

    public var type: ItemContentType {
        switch self {
        case .alias:
            return .alias
        case .login:
            return .login
        case .note:
            return .note
        }
    }
}

public struct LogInItemData {
    public let username: String
    public let password: String
    public let totpUri: String
    public let urls: [String]

    public init(username: String, password: String, totpUri: String, urls: [String]) {
        self.username = username
        self.password = password
        self.totpUri = totpUri
        self.urls = urls
    }
}

public protocol ItemContentProtocol {
    // Metadata
    var name: String { get }
    var note: String { get }

    // Custom data
    var contentData: ItemContentData { get }
}

public typealias ItemContentProtobuf = ProtonPassItemV1_Item
public typealias ProtobufableItemContentProtocol = ItemContentProtocol & Protobufable

extension ItemContentProtobuf: ProtobufableItemContentProtocol {
    public var name: String { metadata.name }
    public var note: String { metadata.note }
    public var uuid: String { metadata.itemUuid }

    public var contentData: ItemContentData {
        switch content.content {
        case .alias:
            return .alias
        case .note:
            return .note
        case .login(let data):
            return .login(.init(username: data.username,
                                password: data.password,
                                totpUri: data.totpUri,
                                urls: data.urls))
        case .none:
            return .note
        }
    }

    public func data() throws -> Data {
        try self.serializedData()
    }

    public init(data: Data) throws {
        self = try ItemContentProtobuf(serializedData: data)
    }

    public init(name: String,
                note: String,
                itemUuid: String,
                data: ItemContentData) {
        metadata = .init()
        metadata.itemUuid = itemUuid
        metadata.name = name
        metadata.note = note
        switch data {
        case .alias:
            content.alias = .init()

        case .login(let logInData):
            content.login = .init()
            content.login.username = logInData.username
            content.login.password = logInData.password
            content.login.totpUri = logInData.totpUri
            content.login.urls = logInData.urls

        case .note:
            content.note = .init()
        }
    }
}

public struct ItemContent: ItemContentProtocol {
    public let shareId: String
    public let itemUuid: String
    public let item: ItemRevision
    public let name: String
    public let note: String
    public let contentData: ItemContentData

    public init(shareId: String,
                item: ItemRevision,
                contentProtobuf: ItemContentProtobuf) {
        self.shareId = shareId
        self.item = item
        self.itemUuid = contentProtobuf.uuid
        self.name = contentProtobuf.name
        self.note = contentProtobuf.note
        self.contentData = contentProtobuf.contentData
    }

    public var protobuf: ItemContentProtobuf {
        .init(name: name, note: note, itemUuid: itemUuid, data: contentData)
    }
}

extension ItemContent: ItemIdentifiable {
    public var itemId: String { item.itemID }
}

extension ItemContent: ItemTypeIdentifiable {
    public var type: ItemContentType { contentData.type }
}

extension ItemContent: ItemThumbnailable {
    public var title: String { name }

    public var url: String? {
        switch contentData {
        case .login(let data):
            return data.urls.first
        default:
            return nil
        }
    }
}

public extension ItemContent {
    /// Get `TOTPData` of the current moment
    func totpData() throws -> TOTPData? {
        if case .login(let logInData) = contentData,
           !logInData.totpUri.isEmpty {
            return try .init(uri: logInData.totpUri)
        } else {
            return nil
        }
    }
}

// MARK: - Symmetric encryption/decryption
public extension ItemContentProtobuf {
    /// Symmetrically encrypt and base 64 the binary data
    func encrypt(symmetricKey: SymmetricKey) throws -> String {
        let clearData = try data()
        let cypherData = try symmetricKey.encrypt(clearData)
        return cypherData.base64EncodedString()
    }

    init(base64: String, symmetricKey: SymmetricKey) throws {
        guard let cypherData = try base64.base64Decode() else {
            throw PPClientError.crypto(.failedToBase64Decode)
        }
        let clearData = try symmetricKey.decrypt(cypherData)
        try self.init(data: clearData)
    }
}
