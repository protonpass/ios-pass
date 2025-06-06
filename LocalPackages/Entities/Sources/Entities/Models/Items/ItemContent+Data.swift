//
// ItemContent+Data.swift
// Proton Pass - Created on 24/05/2024.
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

import Foundation

public enum ItemContentData: Sendable, Equatable, Hashable {
    case alias
    case login(LogInItemData)
    case note
    case creditCard(CreditCardData)
    case identity(IdentityData)
    case sshKey(SshKeyData)
    case wifi(WifiData)
    case custom(CustomItemData)

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
        case .sshKey:
            .sshKey
        case .wifi:
            .wifi
        case .custom:
            .custom
        }
    }
}

// MARK: - Login

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

extension LogInItemData: UsernameEmailContainer {}

// MARK: - Credit card

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

// MARK: - Identity

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
    public let linkedIn: String
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
                  linkedIn: data.linkedin,
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
                linkedIn: String,
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
        self.linkedIn = linkedIn
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

extension IdentityData {
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
        item.linkedin = linkedIn
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
        item.extraSections = extraSections.toProtonPassItemV1CustomSections
        return item
    }
}

// MARK: - SSH key

public struct SshKeyData: Sendable, Equatable, Hashable {
    public let privateKey: String
    public let publicKey: String
    public let extraSections: [CustomSection]

    public init(from data: ProtonPassItemV1_ItemSSHKey) {
        privateKey = data.privateKey
        publicKey = data.publicKey
        extraSections = data.sections.map { CustomSection(from: $0) }
    }

    public init(privateKey: String,
                publicKey: String,
                extraSections: [CustomSection]) {
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.extraSections = extraSections
    }
}

public extension SshKeyData {
    var toProtonPassItemV1ItemSshKey: ProtonPassItemV1_ItemSSHKey {
        var item = ProtonPassItemV1_ItemSSHKey()
        item.privateKey = privateKey
        item.publicKey = publicKey
        item.sections = extraSections.toProtonPassItemV1CustomSections
        return item
    }
}

// MARK: - Wifi

public struct WifiData: Sendable, Equatable, Hashable {
    public let ssid: String
    public let password: String
    public let security: Security
    public let extraSections: [CustomSection]

    public enum Security: Sendable, CaseIterable {
        case unspecified, wpa, wpa2, wpa3, wep

        public var protocolName: String {
            switch self {
            case .unspecified: "WPA2" // Default to WPA2
            case .wpa: "WPA"
            case .wpa2: "WPA2"
            case .wpa3: "WPA3"
            case .wep: "WEP"
            }
        }
    }

    public init(from data: ProtonPassItemV1_ItemWifi) {
        ssid = data.ssid
        password = data.password
        security = switch data.security {
        case .unspecifiedWifiSecurity: .unspecified
        case .wpa: .wpa
        case .wpa2: .wpa2
        case .wpa3: .wpa3
        case .wep: .wep
        default: .unspecified
        }
        extraSections = data.sections.map { CustomSection(from: $0) }
    }

    public init(ssid: String,
                password: String,
                security: Security,
                extraSections: [CustomSection]) {
        self.ssid = ssid
        self.password = password
        self.security = security
        self.extraSections = extraSections
    }
}

public extension WifiData {
    var toProtonPassItemV1ItemWifi: ProtonPassItemV1_ItemWifi {
        var item = ProtonPassItemV1_ItemWifi()
        item.ssid = ssid
        item.password = password
        item.security = switch security {
        case .unspecified: .unspecifiedWifiSecurity
        case .wpa: .wpa
        case .wpa2: .wpa2
        case .wpa3: .wpa3
        case .wep: .wep
        }
        item.sections = extraSections.toProtonPassItemV1CustomSections
        return item
    }
}

// MARK: - Custom

public struct CustomItemData: Sendable, Equatable, Hashable {
    public let sections: [CustomSection]

    public init(from data: ProtonPassItemV1_ItemCustom) {
        sections = data.sections.map { CustomSection(from: $0) }
    }

    public init(sections: [CustomSection]) {
        self.sections = sections
    }
}

public extension CustomItemData {
    var toProtonPassItemV1ItemCustom: ProtonPassItemV1_ItemCustom {
        var item = ProtonPassItemV1_ItemCustom()
        item.sections = sections.toProtonPassItemV1CustomSections
        return item
    }
}

public extension [CustomField] {
    var toProtonPassItemV1ExtraFields: [ProtonPassItemV1_ExtraField] {
        map { customField in
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

            case .timestamp:
                extraField.timestamp = .init()
                if let intValue = Int64(customField.content) {
                    extraField.timestamp.timestamp.seconds = intValue
                }
            }

            return extraField
        }
    }
}

public extension [CustomSection] {
    var toProtonPassItemV1CustomSections: [ProtonPassItemV1_CustomSection] {
        map { section in
            var customSection = ProtonPassItemV1_CustomSection()
            customSection.sectionName = section.title
            customSection.sectionFields = section.content.toProtonPassItemV1ExtraFields
            return customSection
        }
    }
}
