//
//
// IdentityDetailViewModel.swift
// Proton Pass - Created on 27/05/2024.
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
//

import Combine
import Core
import Entities
import Factory
import Macro
import SwiftUI
import UIKit

extension IdentityDetailViewModel {
    struct Section: Identifiable {
        let title: String
        let rows: [Row]
        let customFields: [CustomFieldUiModel]

        var id: String {
            title
        }

        init(title: String, rows: [Row], customFields: [CustomFieldUiModel]) {
            self.title = title
            self.rows = rows.filter { !$0.value.isEmpty }
            self.customFields = customFields
        }

        var isEmpty: Bool {
            rows.isEmpty && customFields.isEmpty
        }
    }

    struct Row: Identifiable, Equatable {
        let title: String
        let value: String

        var id: String {
            title + value
        }
    }
}

@MainActor
final class IdentityDetailViewModel: BaseItemDetailViewModel {
    @Published private(set) var title = ""
    @Published private(set) var firstName = ""
    @Published private(set) var middleName = ""
    @Published private(set) var lastName = ""
    @Published private(set) var fullName = ""
    @Published private(set) var email = ""
    @Published private(set) var phoneNumber = ""
    @Published private(set) var birthdate = ""
    @Published private(set) var gender = ""
    @Published private(set) var extraPersonalDetails: [CustomFieldUiModel] = []
    @Published private(set) var organization = ""
    @Published private(set) var streetAddress = ""
    @Published private(set) var zipOrPostalCode = ""
    @Published private(set) var city = ""
    @Published private(set) var stateOrProvince = ""
    @Published private(set) var countryOrRegion = ""
    @Published private(set) var floor = ""
    @Published private(set) var county = ""
    @Published private(set) var extraAddressDetails: [CustomFieldUiModel] = []
    @Published private(set) var socialSecurityNumber = ""
    @Published private(set) var passportNumber = ""
    @Published private(set) var licenseNumber = ""
    @Published private(set) var website = ""
    @Published private(set) var xHandle = ""
    @Published private(set) var secondPhoneNumber = ""
    @Published private(set) var linkedIn = ""
    @Published private(set) var reddit = ""
    @Published private(set) var facebook = ""
    @Published private(set) var yahoo = ""
    @Published private(set) var instagram = ""
    @Published private(set) var extraContactDetails: [CustomFieldUiModel] = []
    @Published private(set) var company = ""
    @Published private(set) var jobTitle = ""
    @Published private(set) var personalWebsite = ""
    @Published private(set) var workPhoneNumber = ""
    @Published private(set) var workEmail = ""
    @Published private(set) var extraWorkDetails: [CustomFieldUiModel] = []
    @Published private(set) var extraSections: [CustomSection] = []

    override func bindValues() {
        super.bindValues()
        guard case let .identity(data) = itemContent.contentData else {
            return
        }
        title = itemContent.name
        fullName = data.fullName
        email = data.email
        phoneNumber = data.phoneNumber
        firstName = data.firstName
        middleName = data.middleName
        lastName = data.lastName
        birthdate = data.birthdate
        gender = data.gender
        extraPersonalDetails = data.extraPersonalDetails.map(\.toCustomFieldUiModel)
        organization = data.organization
        streetAddress = data.streetAddress
        zipOrPostalCode = data.zipOrPostalCode
        city = data.city
        stateOrProvince = data.stateOrProvince
        countryOrRegion = data.countryOrRegion
        floor = data.floor
        county = data.county
        extraAddressDetails = data.extraAddressDetails.map(\.toCustomFieldUiModel)
        socialSecurityNumber = data.socialSecurityNumber
        passportNumber = data.passportNumber
        licenseNumber = data.licenseNumber
        website = data.website
        xHandle = data.xHandle
        secondPhoneNumber = data.secondPhoneNumber
        linkedIn = data.linkedIn
        reddit = data.reddit
        facebook = data.facebook
        yahoo = data.yahoo
        instagram = data.instagram
        extraContactDetails = data.extraContactDetails.map(\.toCustomFieldUiModel)
        company = data.company
        jobTitle = data.jobTitle

        personalWebsite = data.personalWebsite
        workPhoneNumber = data.workPhoneNumber
        workEmail = data.workEmail
        extraWorkDetails = data.extraWorkDetails.map(\.toCustomFieldUiModel)
        extraSections = data.extraSections
    }

    var sections: [Section] {
        [personalDetailsSection, addressDetailsSection, contactDetailsSection, workDetailsSection]
    }
}

private extension IdentityDetailViewModel {
    var personalDetailsSection: Section {
        .init(title: #localized("Personal details"),
              rows: [
                  .init(title: IdentityFields.firstName.title, value: firstName),
                  .init(title: IdentityFields.middleName.title, value: middleName),
                  .init(title: IdentityFields.lastName.title, value: lastName),
                  .init(title: IdentityFields.fullName.title, value: fullName),
                  .init(title: IdentityFields.email.title, value: email),
                  .init(title: IdentityFields.phoneNumber.title, value: phoneNumber),
                  .init(title: IdentityFields.birthdate.title, value: birthdate),
                  .init(title: IdentityFields.gender.title, value: gender)
              ],
              customFields: extraPersonalDetails)
    }

    var addressDetailsSection: Section {
        .init(title: #localized("Address details"),
              rows: [
                  .init(title: IdentityFields.organization.title, value: organization),
                  .init(title: IdentityFields.streetAddress.title, value: streetAddress),
                  .init(title: IdentityFields.zipOrPostalCode.title, value: zipOrPostalCode),
                  .init(title: IdentityFields.city.title, value: city),
                  .init(title: IdentityFields.stateOrProvince.title, value: stateOrProvince),
                  .init(title: IdentityFields.countryOrRegion.title, value: countryOrRegion),
                  .init(title: IdentityFields.floor.title, value: floor),
                  .init(title: IdentityFields.county.title, value: county)
              ],
              customFields: extraAddressDetails)
    }

    var contactDetailsSection: Section {
        .init(title: #localized("Contact details"),
              rows: [
                  .init(title: IdentityFields.socialSecurityNumber.title, value: socialSecurityNumber),
                  .init(title: IdentityFields.passportNumber.title, value: passportNumber),
                  .init(title: IdentityFields.licenseNumber.title, value: licenseNumber),
                  .init(title: IdentityFields.website.title, value: website),
                  .init(title: IdentityFields.xHandle.title, value: xHandle),
                  .init(title: IdentityFields.secondPhoneNumber.title, value: secondPhoneNumber),
                  .init(title: IdentityFields.linkedIn.title, value: linkedIn),
                  .init(title: IdentityFields.reddit.title, value: reddit),
                  .init(title: IdentityFields.facebook.title, value: facebook),
                  .init(title: IdentityFields.yahoo.title, value: yahoo),
                  .init(title: IdentityFields.instagram.title, value: instagram)
              ],
              customFields: extraContactDetails)
    }

    var workDetailsSection: Section {
        .init(title: #localized("Work details"),
              rows: [
                  .init(title: IdentityFields.company.title, value: company),
                  .init(title: IdentityFields.jobTitle.title, value: jobTitle),
                  .init(title: IdentityFields.personalWebsite.title, value: personalWebsite),
                  .init(title: IdentityFields.workPhoneNumber.title, value: workPhoneNumber),
                  .init(title: IdentityFields.workEmail.title, value: workEmail)
              ],
              customFields: extraWorkDetails)
    }
}

extension IdentityDetailViewModel {
    func copyToClipboard(_ row: Row) {
        copyToClipboard(text: row.value, message: #localized("%@ copied", row.title))
    }

    func copyTotpToken(_ token: String) {
        copyToClipboard(text: token, message: #localized("TOTP copied"))
    }

    func copyHiddenText(_ text: String) {
        copyToClipboard(text: text, message: #localized("Hidden text copied"))
    }
}
