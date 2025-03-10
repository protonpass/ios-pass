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
            itemContentProtobuf.content.login.itemUsername = logInData.username
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
        case let .identity(data):
            itemContentProtobuf.content.identity = .init()
            itemContentProtobuf.content.identity.fullName = data.fullName
            itemContentProtobuf.content.identity.email = data.email
            itemContentProtobuf.content.identity.phoneNumber = data.phoneNumber
            itemContentProtobuf.content.identity.firstName = data.firstName
            itemContentProtobuf.content.identity.middleName = data.middleName
            itemContentProtobuf.content.identity.lastName = data.lastName
            itemContentProtobuf.content.identity.birthdate = data.birthdate
            itemContentProtobuf.content.identity.gender = data.gender
            itemContentProtobuf.content.identity.extraPersonalDetails = data.extraPersonalDetails.toProtonPassItemV1ExtraFields
            itemContentProtobuf.content.identity.organization = data.organization
            itemContentProtobuf.content.identity.streetAddress = data.streetAddress
            itemContentProtobuf.content.identity.zipOrPostalCode = data.zipOrPostalCode
            itemContentProtobuf.content.identity.city = data.city
            itemContentProtobuf.content.identity.stateOrProvince = data.stateOrProvince
            itemContentProtobuf.content.identity.countryOrRegion = data.countryOrRegion
            itemContentProtobuf.content.identity.floor = data.floor
            itemContentProtobuf.content.identity.county = data.county
            itemContentProtobuf.content.identity.extraAddressDetails = data.extraAddressDetails.toProtonPassItemV1ExtraFields
            itemContentProtobuf.content.identity.socialSecurityNumber = data.socialSecurityNumber
            itemContentProtobuf.content.identity.passportNumber = data.passportNumber
            itemContentProtobuf.content.identity.licenseNumber = data.licenseNumber
            itemContentProtobuf.content.identity.website = data.website
            itemContentProtobuf.content.identity.xHandle = data.xHandle
            itemContentProtobuf.content.identity.secondPhoneNumber = data.secondPhoneNumber
            itemContentProtobuf.content.identity.linkedin = data.linkedIn
            itemContentProtobuf.content.identity.reddit = data.reddit
            itemContentProtobuf.content.identity.facebook = data.facebook
            itemContentProtobuf.content.identity.yahoo = data.yahoo
            itemContentProtobuf.content.identity.instagram = data.instagram
            itemContentProtobuf.content.identity.extraContactDetails = data.extraContactDetails.toProtonPassItemV1ExtraFields
            itemContentProtobuf.content.identity.company = data.company
            itemContentProtobuf.content.identity.jobTitle = data.jobTitle
            itemContentProtobuf.content.identity.personalWebsite = data.personalWebsite
            itemContentProtobuf.content.identity.workPhoneNumber = data.workPhoneNumber
            itemContentProtobuf.content.identity.workEmail = data.workEmail
            itemContentProtobuf.content.identity.extraWorkDetails = data.extraWorkDetails.toProtonPassItemV1ExtraFields
            itemContentProtobuf.content.identity.extraSections = data.extraSections.toProtonPassItemV1CustomSections

        case let .sshKey(data):
            itemContentProtobuf.content.sshKey = .init()
            itemContentProtobuf.content.sshKey.privateKey = data.privateKey
            itemContentProtobuf.content.sshKey.publicKey = data.publicKey
            itemContentProtobuf.content.sshKey.sections = data.extraSections.toProtonPassItemV1CustomSections

        case let .wifi(data):
            itemContentProtobuf.content.wifi = .init()
            itemContentProtobuf.content.wifi.ssid = data.ssid
            itemContentProtobuf.content.wifi.password = data.password
            itemContentProtobuf.content.wifi.sections = data.extraSections.toProtonPassItemV1CustomSections

        case let .custom(data):
            itemContentProtobuf.content.custom = .init()
            itemContentProtobuf.content.custom.sections = data.sections.toProtonPassItemV1CustomSections
        }
        
        itemContentProtobuf.extraFields = customFields.toProtonPassItemV1ExtraFields
        
        return itemContentProtobuf
    }
}
