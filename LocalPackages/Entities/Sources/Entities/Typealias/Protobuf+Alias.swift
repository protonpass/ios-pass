//
// Protobuf+Alias.swift
// Proton Pass - Created on 24/11/2023.
// Copyright (c) 2023 Proton Technologies AG
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

public typealias ItemContentProtobuf = ProtonPassItemV1_Item
public typealias ProtobufableItemContentProtocol = ItemContentProtocol & Protobufable
public typealias AllowedAndroidApp = ProtonPassItemV1_AllowedAndroidApp
public typealias Passkey = ProtonPassItemV1_Passkey

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
            .login(.init(email: data.itemEmail,
                         username: data.itemUsername,
                         password: data.password,
                         totpUri: data.totpUri,
                         urls: data.urls,
                         allowedAndroidApps: platformSpecific.android.allowedApps,
                         passkeys: data.passkeys))

        case .none:
            .note

        case let .identity(data):
            .identity(IdentityData(from: data))

        case let .sshKey(data):
            .sshKey(.init(from: data))

        case let .wifi(data):
            .wifi(.init(from: data))

        case let .custom(data):
            .custom(.init(from: data))
        }
    }

    public var customFields: [CustomField] { extraFields.map { .init(from: $0) } }

    public func data() throws -> Data {
        try serializedData()
    }

    public init(data: Data) throws {
        self = try ItemContentProtobuf(serializedBytes: data)
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
            content.login.itemEmail = logInData.email
            content.login.itemUsername = logInData.username
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

        case let .identity(data):
            content.identity = data.toProtonPassItemV1ItemIdentity

        case let .sshKey(data):
            content.sshKey = .init()
            content.sshKey.privateKey = data.privateKey
            content.sshKey.publicKey = data.publicKey
            content.sshKey.sections = data.extraSections.toProtonPassItemV1CustomSections

        case let .wifi(data):
            content.wifi = .init()
            content.wifi.ssid = data.ssid
            content.wifi.password = data.password
            content.wifi.sections = data.extraSections.toProtonPassItemV1CustomSections

        case let .custom(data):
            content.custom = .init()
            content.custom.sections = data.sections.toProtonPassItemV1CustomSections
        }

        extraFields = customFields.toProtonPassItemV1ExtraFields
    }
}
