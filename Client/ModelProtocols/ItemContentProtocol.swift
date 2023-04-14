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

extension ItemContentData: SymmetricallyEncryptable {
    public func symmetricallyEncrypted(_ symmetricKey: SymmetricKey) throws -> ItemContentData {
        switch self {
        case .alias, .note:
            return self
        case .login(let data):
            let encryptedUsername = try symmetricKey.encrypt(data.username)
            let encryptedPassword = try symmetricKey.encrypt(data.password)
            let encryptedTotpUri = try symmetricKey.encrypt(data.totpUri)
            let encryptedUrls = try data.urls.map { try symmetricKey.encrypt($0) }
            return .login(.init(username: encryptedUsername,
                                password: encryptedPassword,
                                totpUri: encryptedTotpUri,
                                urls: encryptedUrls))
        }
    }

    public func symmetricallyDecrypted(_ symmetricKey: SymmetricKey) throws -> ItemContentData {
        switch self {
        case .alias, .note:
            return self
        case .login(let data):
            let decryptedUsername = try symmetricKey.decrypt(data.username)
            let decryptedPassword = try symmetricKey.decrypt(data.password)
            let decryptedTotpUri = try symmetricKey.decrypt(data.totpUri)
            let decryptedUrls = try data.urls.map { try symmetricKey.decrypt($0) }
            return .login(.init(username: decryptedUsername,
                                password: decryptedPassword,
                                totpUri: decryptedTotpUri,
                                urls: decryptedUrls))
        }
    }
}

extension ItemContentProtobuf: SymmetricallyEncryptable {
    public func symmetricallyEncrypted(_ symmetricKey: SymmetricKey) throws -> ItemContentProtobuf {
        let encryptedName = try symmetricKey.encrypt(name)
        let encryptedNote = try symmetricKey.encrypt(note)
        let encryptedData = try contentData.symmetricallyEncrypted(symmetricKey)
        return .init(name: encryptedName,
                     note: encryptedNote,
                     itemUuid: uuid,
                     data: encryptedData)
    }

    public func symmetricallyDecrypted(_ symmetricKey: SymmetricKey) throws -> ItemContentProtobuf {
        let decryptedName = try symmetricKey.decrypt(name)
        let decryptedNote = try symmetricKey.decrypt(note)
        let decryptedData = try contentData.symmetricallyDecrypted(symmetricKey)
        return .init(name: decryptedName,
                     note: decryptedNote,
                     itemUuid: uuid,
                     data: decryptedData)
    }
}
