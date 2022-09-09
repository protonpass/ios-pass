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

import ProtonCore_UIFoundations
import UIKit

public enum ItemContentType: CaseIterable {
    case alias
    case login
    case note

    public var icon: UIImage {
        switch self {
        case .alias:
            return IconProvider.alias
        case .login:
            return IconProvider.keySkeleton
        case .note:
            return IconProvider.note
        }
    }
}

public enum ItemContentData {
    case alias
    case login(username: String, password: String, urls: [String])
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

    public var contentData: ItemContentData {
        switch content.content {
        case .alias:
            return .alias
        case .note:
            return .note
        case .login(let login):
            return .login(username: login.username,
                          password: login.password,
                          urls: login.urls)
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
        metadata = .init()
        metadata.name = name
        metadata.note = note
        switch data {
        case .alias:
            content.alias = .init()

        case let .login(username, password, urls):
            content.login = .init()
            content.login.username = username
            content.login.password = password
            content.login.urls = urls

        case .note:
            content.note = .init()
        }
    }
}

public struct ItemContent: ItemContentProtocol {
    public let shareId: String
    public let itemId: String
    public let name: String
    public let note: String
    public let contentData: ItemContentData

    public init(shareId: String,
                itemId: String,
                name: String,
                note: String,
                contentData: ItemContentData) {
        self.shareId = shareId
        self.itemId = itemId
        self.name = name
        self.note = note
        self.contentData = contentData
    }
}
