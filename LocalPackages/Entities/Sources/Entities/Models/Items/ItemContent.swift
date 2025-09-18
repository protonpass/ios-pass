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
    public let customFields: [CustomField]
    public let simpleLoginNote: String?

    /// Applicable to identities, ssh keys, wifis and custom items
    public var customSections: [CustomSection] {
        switch contentData {
        case let .identity(data):
            data.extraSections
        case let .sshKey(data):
            data.extraSections
        case let .wifi(data):
            data.extraSections
        case let .custom(data):
            data.sections
        default:
            []
        }
    }

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
                customFields: [CustomField],
                simpleLoginNote: String?) {
        self.shareId = shareId
        self.itemUuid = itemUuid
        self.userId = userId
        self.item = item
        self.name = name
        self.note = note
        self.contentData = contentData
        self.customFields = customFields
        self.simpleLoginNote = simpleLoginNote
    }

    public init(userId: String,
                shareId: String,
                item: Item,
                contentProtobuf: ItemContentProtobuf,
                simpleLoginNote: String?) {
        self.shareId = shareId
        self.item = item
        self.userId = userId
        itemUuid = contentProtobuf.uuid
        name = contentProtobuf.name
        note = contentProtobuf.note
        contentData = contentProtobuf.contentData
        customFields = contentProtobuf.customFields
        self.simpleLoginNote = simpleLoginNote
    }

    public var protobuf: ItemContentProtobuf {
        .init(name: name,
              note: note,
              itemUuid: itemUuid,
              data: contentData,
              customFields: customFields)
    }

    /// Used as item's secondary title (description). Only applicable to SSH key & custom item types.
    public var firstTextCustomFieldValue: String? {
        let sections: [CustomSection] = switch contentData {
        case let .sshKey(data):
            data.extraSections
        case let .custom(data):
            data.sections
        default:
            []
        }
        let applicableFields = (customFields + sections.flatMap(\.content)).filter { $0.type == .text }
        return applicableFields.first?.content
    }

    // Must be careful because this does not always represent a shared item that was accepted by user as it also
    // show in send. To know if an item was share with me we need to check this one and check that item.itemkey is
    // nil
    public var shared: Bool { item.shareCount > 0 }
}

extension ItemContent: ItemIdentifiable {
    public var itemId: String { item.itemID }
}

extension ItemContent: ItemTypeIdentifiable {
    public var type: ItemContentType { contentData.type }
    public var totpUri: String? {
        if case let .login(data) = contentData {
            data.totpUri
        } else {
            nil
        }
    }

    public var aliasEmail: String? { item.aliasEmail }
    public var aliasEnabled: Bool { item.isAliasEnabled }

    public var hasEmail: Bool {
        if case let .login(data) = contentData {
            !data.email.isEmpty
        } else {
            false
        }
    }

    public var hasUsername: Bool {
        if case let .login(data) = contentData {
            !data.username.isEmpty
        } else {
            false
        }
    }

    public var hasPassword: Bool {
        if case let .login(data) = contentData {
            !data.password.isEmpty
        } else {
            false
        }
    }
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
        if case let .login(data) = contentData {
            return data
        }
        return nil
    }

    var creditCardItem: CreditCardData? {
        if case let .creditCard(data) = contentData {
            return data
        }
        return nil
    }

    var identityItem: IdentityData? {
        if case let .identity(data) = contentData {
            return data
        }
        return nil
    }

    var sshKey: SshKeyData? {
        if case let .sshKey(data) = contentData {
            return data
        }
        return nil
    }

    var wifi: WifiData? {
        if case let .wifi(data) = contentData {
            return data
        }
        return nil
    }

    var custom: CustomItemData? {
        if case let .custom(data) = contentData {
            return data
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
            case let .wifi(data):
                contents.append(contentsOf: [data.ssid])
            case .custom, .sshKey:
                // Explicit opt-out
                break
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
