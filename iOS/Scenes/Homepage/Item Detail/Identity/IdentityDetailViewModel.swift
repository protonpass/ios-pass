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
import Entities
import Factory
import Macro
import SwiftUI
import UIKit

@MainActor
final class IdentityDetailViewModel: BaseItemDetailViewModel {
    @Published private(set) var title = ""
    @Published private(set) var fullName = ""
    @Published private(set) var email = ""
    @Published private(set) var phoneNumber = ""
    @Published private(set) var firstName = ""
    @Published private(set) var middleName = ""
    @Published private(set) var lastName = ""
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

    var showPersonalSection: Bool {
        !title.isEmpty || !fullName.isEmpty ||
            !email.isEmpty || !phoneNumber.isEmpty ||
            !firstName.isEmpty || !middleName.isEmpty ||
            !lastName.isEmpty || !birthdate.isEmpty ||
            !gender.isEmpty || !extraPersonalDetails.isEmpty
    }

    var showAddressSection: Bool {
        !organization.isEmpty || !streetAddress.isEmpty ||
            !zipOrPostalCode.isEmpty || !city.isEmpty ||
            !stateOrProvince.isEmpty || !countryOrRegion.isEmpty ||
            !floor.isEmpty || !county.isEmpty || !extraAddressDetails.isEmpty
    }

    var showContactSection: Bool {
        !socialSecurityNumber.isEmpty || !passportNumber.isEmpty ||
            !licenseNumber.isEmpty || !website.isEmpty ||
            !xHandle.isEmpty || !secondPhoneNumber.isEmpty ||
            !linkedIn.isEmpty || !reddit.isEmpty || !facebook.isEmpty ||
            !yahoo.isEmpty || !instagram.isEmpty || !extraContactDetails.isEmpty
    }

    var showWordSection: Bool {
        !company.isEmpty || !jobTitle.isEmpty ||
            !personalWebsite.isEmpty || !workPhoneNumber.isEmpty ||
            !workEmail.isEmpty || !extraWorkDetails.isEmpty
    }

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
}

extension IdentityDetailViewModel {
    func copyValueToClipboard(value: String, message: String) {
        copyToClipboard(text: value, message: #localized("%@ copied", message))
    }

    func copyTotpToken(_ token: String) {
        copyToClipboard(text: token, message: #localized("TOTP copied"))
    }

    func copyHiddenText(_ text: String) {
        copyToClipboard(text: text, message: #localized("Hidden text copied"))
    }
}
