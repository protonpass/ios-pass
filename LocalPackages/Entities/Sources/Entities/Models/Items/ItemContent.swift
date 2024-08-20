//
// ItemContent.swift
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

import CoreSpotlight
import Foundation

public protocol ItemContentProtocol: Sendable {
    var name: String { get }
    var note: String { get }
    var contentData: ItemContentData { get }
    var customFields: [CustomField] { get }
}

public struct ItemContent: ItemContentProtocol, Sendable, Equatable, Hashable, Identifiable {
    public let shareId: String
    public let itemUuid: String
    public let userId: String
    public let item: Item
    public let name: String
    public let note: String
    public let contentData: ItemContentData

    /// Should only be used for login items
    public let customFields: [CustomField]

    public var id: String {
        "\(item.itemID + shareId)"
    }

    public init(shareId: String,
                itemUuid: String,
                userId: String,
                item: Item,
                name: String,
                note: String,
                contentData: ItemContentData,
                customFields: [CustomField]) {
        self.shareId = shareId
        self.itemUuid = itemUuid
        self.userId = userId
        self.item = item
        self.name = name
        self.note = note
        self.contentData = contentData
        self.customFields = customFields
    }

    public init(userId: String,
                shareId: String,
                item: Item,
                contentProtobuf: ItemContentProtobuf) {
        self.shareId = shareId
        self.item = item
        self.userId = userId
        itemUuid = contentProtobuf.uuid
        name = contentProtobuf.name
        note = contentProtobuf.note
        contentData = contentProtobuf.contentData
        customFields = contentProtobuf.customFields
    }

    public var protobuf: ItemContentProtobuf {
        .init(name: name,
              note: note,
              itemUuid: itemUuid,
              data: contentData,
              customFields: customFields)
    }
}

extension ItemContent: ItemIdentifiable {
    public var itemId: String { item.itemID }
}

extension ItemContent: ItemTypeIdentifiable {
    public var type: ItemContentType { contentData.type }
    public var aliasEmail: String? { item.aliasEmail }
    public var aliasEnabled: Bool { item.isAliasEnabled }
}

extension ItemContent: ItemThumbnailable {
    public var title: String { name }

    public var url: String? {
        switch contentData {
        case let .login(data):
            data.urls.first
        default:
            nil
        }
    }
}

public extension ItemContent {
    var loginItem: LogInItemData? {
        if case let .login(item) = contentData {
            return item
        }
        return nil
    }

    var creditCardItem: CreditCardData? {
        if case let .creditCard(item) = contentData {
            return item
        }
        return nil
    }

    var identityItem: IdentityData? {
        if case let .identity(item) = contentData {
            return item
        }
        return nil
    }

    var isAlias: Bool {
        if case .alias = contentData {
            return true
        }
        return false
    }

    var hasTotpUri: Bool {
        switch contentData {
        case let .login(data):
            !data.totpUri.isEmpty
        default:
            false
        }
    }

    var email: String? {
        switch contentData {
        case let .login(data):
            data.email
        case let .identity(data):
            data.email
        default:
            nil
        }
    }

    var spotlightDomainId: String {
        type.debugDescription
    }

    func toSearchableItem(content: SpotlightSearchableContent) throws -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .item)
        attributeSet.title = name
        // "displayName" is required by iOS 17
        // https://forums.developer.apple.com/forums/thread/734996?answerId=763586022#763586022
        attributeSet.displayName = name

        var contents = [String?]()

        if content.includeNote {
            contents.append(note)
        }

        if content.includeCustomData {
            switch contentData {
            case .alias:
                contents.append(aliasEmail)
            case let .login(data):
                contents.append(contentsOf: [data.email, data.username] + data.urls)
            case let .creditCard(data):
                contents.append(data.cardholderName)
            case .note:
                break
            case let .identity(data):
                contents.append(contentsOf: [data.fullName, data.email])
            }

            let customFieldValues = customFields
                .filter { $0.type == .text }
                .map { "\($0.title): \($0.content)" }

            contents.append(contentsOf: customFieldValues)
        }

        attributeSet.contentDescription = contents.compactMap { $0 }.joined(separator: "\n")
        let id = try ids.serializeBase64()
        return .init(uniqueIdentifier: id,
                     domainIdentifier: spotlightDomainId,
                     attributeSet: attributeSet)
    }

    /// Parse the item as a login and extract all the fields that can help identify it
    var loginIdentifiableFields: [String] {
        var fields = [String]()
        fields.append(title)
        fields.append(note)
        if let data = loginItem {
            fields.append(data.email)
            fields.append(data.username)
            fields.append(contentsOf: data.urls)
            fields.append(contentsOf: data.passkeys.map(\.domain))
            fields.append(contentsOf: data.passkeys.map(\.rpName))
            fields.append(contentsOf: data.passkeys.map(\.userName))
            fields.append(contentsOf: data.passkeys.map(\.userDisplayName))
        }
        return fields
    }
}
