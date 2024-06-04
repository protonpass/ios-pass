//
// IdentityFields.swift
// Proton Pass - Created on 29/05/2024.
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

import Macro
import SwiftUI

enum IdentityFields {
    case title
    case fullName
    case email
    case phoneNumber
    case firstName
    case middleName
    case lastName
    case birthdate
    case gender
    case organization
    case streetAddress
    case zipOrPostalCode
    case city
    case stateOrProvince
    case countryOrRegion
    case floor
    case county
    case socialSecurityNumber
    case passportNumber
    case licenseNumber
    case website
    case xHandle
    case secondPhoneNumber
    case linkedIn
    case reddit
    case facebook
    case yahoo
    case instagram
    case company
    case jobTitle
    case personalWebsite
    case workPhoneNumber
    case workEmail

    var title: String {
        switch self {
        case .title:
            #localized("Title")
        case .fullName:
            #localized("Full name")
        case .email:
            #localized("Email")
        case .phoneNumber:
            #localized("Phone number")
        case .firstName:
            #localized("First name")
        case .middleName:
            #localized("Middle name")
        case .lastName:
            #localized("Last name")
        case .birthdate:
            #localized("Birthdate")
        case .gender:
            #localized("Gender")
        case .organization:
            #localized("Organization")
        case .streetAddress:
            #localized("Street address, P.O. box")
        case .zipOrPostalCode:
            #localized("ZIP or Postal code")
        case .city:
            #localized("City")
        case .stateOrProvince:
            #localized("State or province")
        case .countryOrRegion:
            #localized("Country or Region")
        case .floor:
            #localized("Floor")
        case .county:
            #localized("County")
        case .socialSecurityNumber:
            #localized("Social security number")
        case .passportNumber:
            #localized("Passport number")
        case .licenseNumber:
            #localized("License number")
        case .website:
            #localized("Website")
        case .xHandle:
            #localized("X handle")
        case .secondPhoneNumber:
            #localized("Second phone number")
        case .linkedIn:
            #localized("LinkedIn")
        case .reddit:
            #localized("Reddit")
        case .facebook:
            #localized("Facebook")
        case .yahoo:
            #localized("Yahoo")
        case .instagram:
            #localized("Instagram")
        case .company:
            #localized("Company")
        case .jobTitle:
            #localized("Job title")
        case .personalWebsite:
            #localized("Personal website")
        case .workPhoneNumber:
            #localized("Work phone number")
        case .workEmail:
            #localized("Work email")
        }
    }
}
