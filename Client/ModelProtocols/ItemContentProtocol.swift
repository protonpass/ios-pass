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

import Foundation

public enum ItemContentType {
    case alias
    case login
    case note
}

public enum ItemContentData {
    case alias
    case login(ItemContentLoginProtocol)
    case note
}

public protocol ItemContentProtocol {
    var itemContentMetadata: ItemContentMetadataProtocol { get }
    var itemContentData: ItemContentData { get }
}

public protocol ItemContentMetadataProtocol {
    var name: String { get }
    var note: String { get }
}

public protocol ItemContentLoginProtocol {
    var username: String { get }
    var password: String { get }
    var urls: [String] { get }
}

typealias ItemContentProtobuf = ProtonPassItemV1_Item
typealias ItemContentMetadataProtobuf = ProtonPassItemV1_Metadata
typealias ItemContentLoginProtobuf = ProtonPassItemV1_ItemLogin

extension ItemContentMetadataProtobuf: ItemContentMetadataProtocol {
    public init(name: String, note: String) {
        self.name = name
        self.note = note
    }
}

extension ItemContentLoginProtobuf: ItemContentLoginProtocol {
    public init(username: String, password: String, urls: [String]) {
        self.username = username
        self.password = password
        self.urls = urls
    }
}

public typealias ProtobufableItemContentProtocol = ItemContentProtocol & Protobufable

extension ItemContentProtobuf: ProtobufableItemContentProtocol {
    public var itemContentMetadata: ItemContentMetadataProtocol { metadata }

    public var itemContentData: ItemContentData {
        switch content.content {
        case .alias:
            return .alias
        case .note:
            return .note
        case .login(let login):
            return .login(login)
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

    public init(name: String, note: String, data: ItemContentData) {
        self.metadata = .init(name: name, note: note)
        switch data {
        case .alias:
            self.content.alias = .init()
        case .login(let login):
            self.content.login = .init(username: login.username,
                                       password: login.password,
                                       urls: login.urls)
        case .note:
            self.content.note = .init()
        }
    }
}

public extension Array where Element == ItemContentProtocol {
    func filter(by contentType: ItemContentType) -> [Element] {
        filter { element in
            switch element.itemContentData {
            case .alias:
                return contentType == .alias
            case .login:
                return contentType == .login
            case .note:
                return contentType == .note
            }
        }
    }
}
