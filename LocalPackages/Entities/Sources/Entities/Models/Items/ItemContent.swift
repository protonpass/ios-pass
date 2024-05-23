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

// TODO: Need to add identity in
public enum ItemContentData: Sendable, Equatable, Hashable {
    case alias
    case login(LogInItemData)
    case note
    case creditCard(CreditCardData)
    case identity(IdentityData)

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
        case .identity:
            .identity
        }
    }
}

public struct LogInItemData: Sendable, Equatable, Hashable {
    public let email: String
    public let username: String
    public let password: String
    public let totpUri: String
    public let urls: [String]
    public let allowedAndroidApps: [AllowedAndroidApp]
    public let passkeys: [Passkey]

    public init(email: String,
                username: String,
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

    /// This variable should be used as the new main authentication variable
    /// It returns either the user's username or the email
    /// This should be user for indexing login items
    public var authIdentifier: String {
        if username.isEmpty {
            return email
        }

        return username
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

public struct IdentityData: Sendable, Equatable, Hashable {
    /// Personal details
    /// Shown
    public let fullName: String
    public let email: String
    public let phoneNumber: String

    /// Additional
    public let firstName: String
    public let middleName: String
    public let lastName: String
    public let birthdate: String
    public let gender: String
    public let extraPersonalDetails: [CustomField]

    /// Address details
    /// Shown
    public let organization: String
    public let streetAddress: String
    public let zipOrPostalCode: String
    public let city: String
    public let stateOrProvince: String
    public let countryOrRegion: String

    /// Additional
    public let floor: String
    public let county: String
    public let extraAddressDetails: [CustomField]

    /// Contact details
    /// Shown
    public let socialSecurityNumber: String
    public let passportNumber: String
    public let licenseNumber: String
    public let website: String
    public let xHandle: String
    public let secondPhoneNumber: String

    /// Additional
    public let linkedin: String
    public let reddit: String
    public let facebook: String
    public let yahoo: String
    public let instagram: String
    public let extraContactDetails: [CustomField]

    /// Work details
    /// Shown
    public let company: String
    public let jobTitle: String

    /// Additional
    public let personalWebsite: String
    public let workPhoneNumber: String
    public let workEmail: String
    public let extraWorkDetails: [CustomField]

    /// Extra sections
    public let extraSections: [CustomSection]

    public init(from data: ProtonPassItemV1_ItemIdentity) {
        self.init(fullName: data.fullName,
                  email: data.email,
                  phoneNumber: data.phoneNumber,
                  firstName: data.firstName,
                  middleName: data.middleName,
                  lastName: data.lastName,
                  birthdate: data.birthdate,
                  gender: data.gender,
                  extraPersonalDetails: data.extraPersonalDetails.map { CustomField(from: $0) },
                  organization: data.organization,
                  streetAddress: data.streetAddress,
                  zipOrPostalCode: data.zipOrPostalCode,
                  city: data.city,
                  stateOrProvince: data.stateOrProvince,
                  countryOrRegion: data.countryOrRegion,
                  floor: data.floor,
                  county: data.county,
                  extraAddressDetails: data.extraAddressDetails.map { CustomField(from: $0) },
                  socialSecurityNumber: data.socialSecurityNumber,
                  passportNumber: data.passportNumber,
                  licenseNumber: data.licenseNumber,
                  website: data.website,
                  xHandle: data.xHandle,
                  secondPhoneNumber: data.secondPhoneNumber,
                  linkedin: data.linkedin,
                  reddit: data.reddit,
                  facebook: data.facebook,
                  yahoo: data.yahoo,
                  instagram: data.instagram,
                  extraContactDetails: data.extraContactDetails.map { CustomField(from: $0) },
                  company: data.company,
                  jobTitle: data.jobTitle,
                  personalWebsite: data.personalWebsite,
                  workPhoneNumber: data.workPhoneNumber,
                  workEmail: data.workEmail,
                  extraWorkDetails: data.extraWorkDetails.map { CustomField(from: $0) },
                  extraSections: data.extraSections.map { CustomSection(from: $0) })
    }

    public init(fullName: String,
                email: String,
                phoneNumber: String,
                firstName: String,
                middleName: String,
                lastName: String,
                birthdate: String,
                gender: String,
                extraPersonalDetails: [CustomField],
                organization: String,
                streetAddress: String,
                zipOrPostalCode: String,
                city: String,
                stateOrProvince: String,
                countryOrRegion: String,
                floor: String,
                county: String,
                extraAddressDetails: [CustomField],
                socialSecurityNumber: String,
                passportNumber: String,
                licenseNumber: String,
                website: String,
                xHandle: String,
                secondPhoneNumber: String,
                linkedin: String,
                reddit: String,
                facebook: String,
                yahoo: String,
                instagram: String,
                extraContactDetails: [CustomField],
                company: String,
                jobTitle: String,
                personalWebsite: String,
                workPhoneNumber: String,
                workEmail: String,
                extraWorkDetails: [CustomField],
                extraSections: [CustomSection]) {
        self.fullName = fullName
        self.email = email
        self.phoneNumber = phoneNumber
        self.firstName = firstName
        self.middleName = middleName
        self.lastName = lastName
        self.birthdate = birthdate
        self.gender = gender
        self.extraPersonalDetails = extraPersonalDetails
        self.organization = organization
        self.streetAddress = streetAddress
        self.zipOrPostalCode = zipOrPostalCode
        self.city = city
        self.stateOrProvince = stateOrProvince
        self.countryOrRegion = countryOrRegion
        self.floor = floor
        self.county = county
        self.extraAddressDetails = extraAddressDetails
        self.socialSecurityNumber = socialSecurityNumber
        self.passportNumber = passportNumber
        self.licenseNumber = licenseNumber
        self.website = website
        self.xHandle = xHandle
        self.secondPhoneNumber = secondPhoneNumber
        self.linkedin = linkedin
        self.reddit = reddit
        self.facebook = facebook
        self.yahoo = yahoo
        self.instagram = instagram
        self.extraContactDetails = extraContactDetails
        self.company = company
        self.jobTitle = jobTitle
        self.personalWebsite = personalWebsite
        self.workPhoneNumber = workPhoneNumber
        self.workEmail = workEmail
        self.extraWorkDetails = extraWorkDetails
        self.extraSections = extraSections
    }
}

private extension IdentityData {
    var toProtonPassItemV1ItemIdentity: ProtonPassItemV1_ItemIdentity {
        var item = ProtonPassItemV1_ItemIdentity()
        item.fullName = fullName
        item.email = email
        item.phoneNumber = phoneNumber
        item.firstName = firstName
        item.middleName = middleName
        item.lastName = lastName
        item.birthdate = birthdate
        item.gender = gender
        item.extraPersonalDetails = extraPersonalDetails.toProtonPassItemV1ExtraFields
        item.organization = organization
        item.streetAddress = streetAddress
        item.zipOrPostalCode = zipOrPostalCode
        item.city = city
        item.stateOrProvince = stateOrProvince
        item.countryOrRegion = countryOrRegion
        item.floor = floor
        item.county = county
        item.extraAddressDetails = extraAddressDetails.toProtonPassItemV1ExtraFields
        item.socialSecurityNumber = socialSecurityNumber
        item.passportNumber = passportNumber
        item.licenseNumber = licenseNumber
        item.website = website
        item.xHandle = xHandle
        item.secondPhoneNumber = secondPhoneNumber
        item.linkedin = linkedin
        item.reddit = reddit
        item.facebook = facebook
        item.yahoo = yahoo
        item.instagram = instagram
        item.extraContactDetails = extraContactDetails.toProtonPassItemV1ExtraFields
        item.company = company
        item.jobTitle = jobTitle
        item.personalWebsite = personalWebsite
        item.workPhoneNumber = workPhoneNumber
        item.workEmail = workEmail
        item.extraWorkDetails = extraWorkDetails.toProtonPassItemV1ExtraFields
        item.extraSections = extraSections.toProtonPassItemV1ExtraIdentitySections
        return item
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

    /// Should only be used for item that are not identity for now
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
        }

//        extraFields = customFields.map { customField in
//            var extraField = ProtonPassItemV1_ExtraField()
//            extraField.fieldName = customField.title
//
//            switch customField.type {
//            case .text:
//                extraField.text = .init()
//                extraField.text.content = customField.content
//
//            case .totp:
//                extraField.totp = .init()
//                extraField.totp.totpUri = customField.content
//
//            case .hidden:
//                extraField.hidden = .init()
//                extraField.hidden.content = customField.content
//            }
//
//            return extraField
//        }
        extraFields = customFields.toProtonPassItemV1ExtraFields
    }
}

extension LogInItemData: UsernameEmailContainer {}

private extension [CustomField] {
    var toProtonPassItemV1ExtraFields: [ProtonPassItemV1_ExtraField] {
        self.map { customField in
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

private extension [CustomSection] {
    var toProtonPassItemV1ExtraIdentitySections: [ProtonPassItemV1_ExtraIdentitySection] {
        self.map { section in
            var extraSection = ProtonPassItemV1_ExtraIdentitySection()
            extraSection.sectionName = section.title
            extraSection.sectionFields = section.content.toProtonPassItemV1ExtraFields
            return extraSection
        }
    }
}
