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

public enum ItemContentData: Sendable, Equatable, Hashable {
    case alias
    case login(LogInItemData)
    case note
    case creditCard(CreditCardData)

    public var type: ItemContentType {
        switch self {
        case .alias:
            .alias
        case .login:
            .login
        case .note:
            .note
        case .creditCard:
            .creditCard
        }
    }
}

public struct LogInItemData: Sendable, Equatable, Hashable {
    public let email: String
    public let username: String?
    public let password: String
    public let totpUri: String
    public let urls: [String]
    public let allowedAndroidApps: [AllowedAndroidApp]
    public let passkeys: [Passkey]

    public init(email: String,
                username: String?,
                password: String,
                totpUri: String,
                urls: [String],
                allowedAndroidApps: [AllowedAndroidApp],
                passkeys: [Passkey]) {
        self.email = email
        self.username = username
        self.password = password
        self.totpUri = totpUri
        self.urls = urls
        self.allowedAndroidApps = allowedAndroidApps
        self.passkeys = passkeys
    }
}

public struct CreditCardData: Sendable, Equatable, Hashable {
    public let cardholderName: String
    public let type: ProtonPassItemV1_CardType
    public let number: String
    public let verificationNumber: String
    public let expirationDate: String // YYYY-MM
    public let pin: String

    public var month: Int {
        Int(expirationDate.components(separatedBy: "-").last ?? "") ?? 0
    }

    public var year: Int {
        Int(expirationDate.components(separatedBy: "-").first ?? "") ?? 0
    }

    public var displayedExpirationDate: String {
        Self.expirationDate(month: month, year: year)
    }

    public init(cardholderName: String,
                type: ProtonPassItemV1_CardType,
                number: String,
                verificationNumber: String,
                expirationDate: String,
                pin: String) {
        self.cardholderName = cardholderName
        self.type = type
        self.number = number
        self.verificationNumber = verificationNumber
        self.expirationDate = expirationDate
        self.pin = pin
    }
}

public extension CreditCardData {
    static func expirationDate(month: Int, year: Int) -> String {
        String(format: "%02d / %02d", month, year % 100)
    }
}

public protocol ItemContentProtocol: Sendable {
    var name: String { get }
    var note: String { get }
    var contentData: ItemContentData { get }
    var customFields: [CustomField] { get }
}

public struct ItemContent: ItemContentProtocol, Sendable, Equatable, Hashable, Identifiable {
    public let shareId: String
    public let itemUuid: String
    public let item: Item
    public let name: String
    public let note: String
    public let contentData: ItemContentData
    public let customFields: [CustomField]

    public var id: String {
        "\(item.itemID + shareId)"
    }

    public init(shareId: String,
                itemUuid: String,
                item: Item,
                name: String,
                note: String,
                contentData: ItemContentData,
                customFields: [CustomField]) {
        self.shareId = shareId
        self.itemUuid = itemUuid
        self.item = item
        self.name = name
        self.note = note
        self.contentData = contentData
        self.customFields = customFields
    }

    public init(shareId: String,
                item: Item,
                contentProtobuf: ItemContentProtobuf) {
        self.shareId = shareId
        self.item = item
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

    var hasTotpUri: Bool {
        switch contentData {
        case let .login(data):
            !data.totpUri.isEmpty
        default:
            false
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
                contents.append(contentsOf: [data.username] + data.urls)
            case let .creditCard(data):
                contents.append(data.cardholderName)
            case .note:
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

extension ItemContentProtobuf: ProtobufableItemContentProtocol {
    public var name: String { metadata.name }
    public var note: String { metadata.note }
    public var uuid: String { metadata.itemUuid }

    public var contentData: ItemContentData {
        switch content.content {
        case .alias:
            .alias

        case .note:
            .note

        case let .creditCard(data):
            .creditCard(.init(cardholderName: data.cardholderName,
                              type: data.cardType,
                              number: data.number,
                              verificationNumber: data.verificationNumber,
                              expirationDate: data.expirationDate,
                              pin: data.pin))

        case let .login(data):
                .login(.init(email: data.email,
                             username: data.username,
                         password: data.password,
                         totpUri: data.totpUri,
                         urls: data.urls,
                         allowedAndroidApps: platformSpecific.android.allowedApps,
                         passkeys: data.passkeys))
        case .none:
            .note
        }
    }

    public var customFields: [CustomField] { extraFields.map { .init(from: $0) } }

    public func data() throws -> Data {
        try serializedData()
    }

    public init(data: Data) throws {
        self = try ItemContentProtobuf(serializedData: data)
    }

    public init(name: String,
                note: String,
                itemUuid: String,
                data: ItemContentData,
                customFields: [CustomField]) {
        self.init()
        metadata = .init()
        metadata.itemUuid = itemUuid
        metadata.name = name
        metadata.note = note

        switch data {
        case .alias:
            content.alias = .init()

        case let .login(logInData):
            content.login = .init()
            content.login.username = logInData.username
            content.login.password = logInData.password
            content.login.totpUri = logInData.totpUri
            content.login.urls = logInData.urls
            content.login.passkeys = logInData.passkeys
            platformSpecific.android.allowedApps = logInData.allowedAndroidApps

        case let .creditCard(data):
            content.creditCard = .init()
            content.creditCard.cardholderName = data.cardholderName
            content.creditCard.cardType = data.type
            content.creditCard.number = data.number
            content.creditCard.verificationNumber = data.verificationNumber
            content.creditCard.expirationDate = data.expirationDate
            content.creditCard.pin = data.pin

        case .note:
            content.note = .init()
        }

        extraFields = customFields.map { customField in
            var extraField = ProtonPassItemV1_ExtraField()
            extraField.fieldName = customField.title

            switch customField.type {
            case .text:
                extraField.text = .init()
                extraField.text.content = customField.content

            case .totp:
                extraField.totp = .init()
                extraField.totp.totpUri = customField.content

            case .hidden:
                extraField.hidden = .init()
                extraField.hidden.content = customField.content
            }

            return extraField
        }
    }
}
