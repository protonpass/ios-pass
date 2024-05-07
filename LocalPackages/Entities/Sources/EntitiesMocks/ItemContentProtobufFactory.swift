//
// ItemContentProtobufFactory.swift
// Proton Pass - Created on 28/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities

public enum ItemContentProtobufFactory {
    public static func createItemContentProtobuf(name: String,
                                                 note: String,
                                                 itemUuid: String,
                                                 data: ItemContentData,
                                                 customFields: [CustomField]) -> ItemContentProtobuf {
        var itemContentProtobuf = ItemContentProtobuf()
        itemContentProtobuf.metadata = .init()
        itemContentProtobuf.metadata.itemUuid = itemUuid
        itemContentProtobuf.metadata.name = name
        itemContentProtobuf.metadata.note = note
        
        switch data {
        case .alias:
            itemContentProtobuf.content.alias = .init()
            
        case let .login(logInData):
            itemContentProtobuf.content.login = .init()
            itemContentProtobuf.content.login.itemEmail = logInData.email
            itemContentProtobuf.content.login.itemUsername = logInData.itemUsername
            itemContentProtobuf.content.login.password = logInData.password
            itemContentProtobuf.content.login.totpUri = logInData.totpUri
            itemContentProtobuf.content.login.urls = logInData.urls
            itemContentProtobuf.content.login.passkeys = logInData.passkeys
            itemContentProtobuf.platformSpecific.android.allowedApps = logInData.allowedAndroidApps
            
        case let .creditCard(data):
            itemContentProtobuf.content.creditCard = .init()
            itemContentProtobuf.content.creditCard.cardholderName = data.cardholderName
            itemContentProtobuf.content.creditCard.cardType = data.type
            itemContentProtobuf.content.creditCard.number = data.number
            itemContentProtobuf.content.creditCard.verificationNumber = data.verificationNumber
            itemContentProtobuf.content.creditCard.expirationDate = data.expirationDate
            itemContentProtobuf.content.creditCard.pin = data.pin
            
        case .note:
            itemContentProtobuf.content.note = .init()
        }
        
        itemContentProtobuf.extraFields = customFields.map { customField in
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
        
        return itemContentProtobuf
    }
}
