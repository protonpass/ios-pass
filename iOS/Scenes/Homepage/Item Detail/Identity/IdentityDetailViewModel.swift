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
import FactoryKit
import Macro
import SwiftUI
import UIKit

@MainActor
final class IdentityDetailViewModel: BaseItemDetailViewModel {
    @Published private(set) var title = ""
    @Published private var identity: IdentityData?

    var extraPersonalDetails: [CustomField] {
        identity?.extraPersonalDetails ?? []
    }

    var extraAddressDetails: [CustomField] {
        identity?.extraAddressDetails ?? []
    }

    var extraContactDetails: [CustomField] {
        identity?.extraContactDetails ?? []
    }

    var extraWorkDetails: [CustomField] {
        identity?.extraWorkDetails ?? []
    }

    var extraSections: [CustomSection] {
        identity?.extraSections ?? []
    }

    override func bindValues() {
        super.bindValues()
        title = itemContent.name
        identity = itemContent.identityItem
    }

    var sections: [IdentityDetailSection] {
        [
            personalDetailsSection,
            addressDetailsSection,
            contactDetailsSection,
            workDetailsSection
        ]
    }
}

private extension IdentityDetailViewModel {
    var personalDetailsSection: IdentityDetailSection {
        .init(title: #localized("Personal details"),
              rows: [
                  .init(title: IdentityFields.firstName.title, value: identity?.firstName),
                  .init(title: IdentityFields.middleName.title, value: identity?.middleName),
                  .init(title: IdentityFields.lastName.title, value: identity?.lastName),
                  .init(title: IdentityFields.fullName.title, value: identity?.fullName),
                  .init(title: IdentityFields.email.title, value: identity?.email),
                  .init(title: IdentityFields.phoneNumber.title, value: identity?.phoneNumber),
                  .init(title: IdentityFields.birthdate.title, value: identity?.birthdate),
                  .init(title: IdentityFields.gender.title, value: identity?.gender)
              ],
              customFields: extraPersonalDetails)
    }

    var addressDetailsSection: IdentityDetailSection {
        .init(title: #localized("Address details"),
              rows: [
                  .init(title: IdentityFields.organization.title, value: identity?.organization),
                  .init(title: IdentityFields.streetAddress.title, value: identity?.streetAddress),
                  .init(title: IdentityFields.zipOrPostalCode.title, value: identity?.zipOrPostalCode),
                  .init(title: IdentityFields.city.title, value: identity?.city),
                  .init(title: IdentityFields.stateOrProvince.title, value: identity?.stateOrProvince),
                  .init(title: IdentityFields.countryOrRegion.title, value: identity?.countryOrRegion),
                  .init(title: IdentityFields.floor.title, value: identity?.floor),
                  .init(title: IdentityFields.county.title, value: identity?.county)
              ],
              customFields: extraAddressDetails)
    }

    var contactDetailsSection: IdentityDetailSection {
        .init(title: #localized("Contact details"),
              rows: [
                  .init(title: IdentityFields.socialSecurityNumber.title,
                        value: identity?.socialSecurityNumber,
                        isSocialSecurityNumber: true),
                  .init(title: IdentityFields.passportNumber.title, value: identity?.passportNumber),
                  .init(title: IdentityFields.licenseNumber.title, value: identity?.licenseNumber),
                  .init(title: IdentityFields.website.title, value: identity?.website),
                  .init(title: IdentityFields.xHandle.title, value: identity?.xHandle),
                  .init(title: IdentityFields.secondPhoneNumber.title, value: identity?.secondPhoneNumber),
                  .init(title: IdentityFields.linkedIn.title, value: identity?.linkedIn),
                  .init(title: IdentityFields.reddit.title, value: identity?.reddit),
                  .init(title: IdentityFields.facebook.title, value: identity?.facebook),
                  .init(title: IdentityFields.yahoo.title, value: identity?.yahoo),
                  .init(title: IdentityFields.instagram.title, value: identity?.instagram)
              ],
              customFields: extraContactDetails)
    }

    var workDetailsSection: IdentityDetailSection {
        .init(title: #localized("Work details"),
              rows: [
                  .init(title: IdentityFields.company.title, value: identity?.company),
                  .init(title: IdentityFields.jobTitle.title, value: identity?.jobTitle),
                  .init(title: IdentityFields.personalWebsite.title, value: identity?.personalWebsite),
                  .init(title: IdentityFields.workPhoneNumber.title, value: identity?.workPhoneNumber),
                  .init(title: IdentityFields.workEmail.title, value: identity?.workEmail)
              ],
              customFields: extraWorkDetails)
    }
}

extension IdentityDetailViewModel {
    func copyToClipboard(_ row: IdentityDetailRow) {
        if let value = row.value {
            copyToClipboard(text: value, message: #localized("%@ copied", row.title))
        }
    }
}
