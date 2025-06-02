//
//
// CreateEditIdentityViewModel.swift
// Proton Pass - Created on 21/05/2024.
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
import Foundation
import Macro

enum BaseIdentitySection: String, CaseIterable {
    case personalDetails
    case address
    case contact
    case workDetail

    var createEditIdentitySection: CreateEditIdentitySection {
        CreateEditIdentitySection(type: self,
                                  isCollapsed: self == .contact || self == .workDetail)
    }
}

@Copyable
struct CreateEditIdentitySection: Hashable, Identifiable {
    var id: String = UUID().uuidString
    let type: BaseIdentitySection
    let isCollapsed: Bool
}

struct HiddenStringValue: Sendable {
    var value: String
    var shouldShow: Bool

    init(value: String) {
        self.value = value
        shouldShow = !value.isEmpty
    }

    static var `default`: Self {
        .init(value: "")
    }
}

@MainActor
final class CreateEditIdentityViewModel: BaseCreateEditItemViewModel {
    /// Personal details
    /// Shown
    @Published var fullName = ""
    @Published var email = ""
    @Published var phoneNumber = ""

    /// Additional
    @Published var firstName: HiddenStringValue = .default
    @Published var middleName: HiddenStringValue = .default
    @Published var lastName: HiddenStringValue = .default
    @Published var birthdate: HiddenStringValue = .default
    @Published var gender: HiddenStringValue = .default
    @Published var extraPersonalDetails: [CustomField] = []

    /// Address details
    /// Shown
    @Published var organization = ""
    @Published var streetAddress = ""
    @Published var zipOrPostalCode = ""
    @Published var city = ""
    @Published var stateOrProvince = ""
    @Published var countryOrRegion = ""

    /// Additional
    @Published var floor: HiddenStringValue = .default
    @Published var county: HiddenStringValue = .default
    @Published var extraAddressDetails: [CustomField] = []

    /// Contact details
    /// Shown
    @Published var socialSecurityNumber = ""
    @Published var passportNumber = ""
    @Published var licenseNumber = ""
    @Published var website = ""
    @Published var xHandle = ""
    @Published var secondPhoneNumber = ""

    /// Additional
    @Published var linkedIn: HiddenStringValue = .default
    @Published var reddit: HiddenStringValue = .default
    @Published var facebook: HiddenStringValue = .default
    @Published var yahoo: HiddenStringValue = .default
    @Published var instagram: HiddenStringValue = .default
    @Published var extraContactDetails: [CustomField] = []

    /// Work details
    /// Shown
    @Published var company = ""
    @Published var jobTitle = ""

    /// Additional
    @Published var personalWebsite: HiddenStringValue = .default
    @Published var workPhoneNumber: HiddenStringValue = .default
    @Published var workEmail: HiddenStringValue = .default
    @Published var extraWorkDetails: [CustomField] = []

    @Published var sections = [CreateEditIdentitySection]()

    private var sectionIdToAddCustomField: String?

    override var itemContentType: ItemContentType { .identity }

    override var supportedCustomFieldTypes: [CustomFieldType] {
        var types = super.supportedCustomFieldTypes
        types.removeAll { $0 == .totp }
        return types
    }

    override func requestAddCustomField(to sectionId: String?) {
        sectionIdToAddCustomField = sectionId
        super.requestAddCustomField(to: sectionId)
    }

    override func addCustomField(_ field: CustomField, to sectionId: String?) {
        guard let sectionId,
              sectionId == sectionIdToAddCustomField,
              sections.map(\.id).contains(sectionId) else {
            super.addCustomField(field, to: sectionId)
            return
        }
        sectionIdToAddCustomField = nil
        sections = sections.map { section in
            guard section.id == sectionId else {
                return section
            }
            recentlyAddedOrEditedField = field

            switch section.type {
            case .address:
                extraAddressDetails.append(field)

            case .personalDetails:
                extraPersonalDetails.append(field)

            case .workDetail:
                extraWorkDetails.append(field)

            case .contact:
                extraContactDetails.append(field)
            }

            return section
        }
    }

    override func editCustomField(_ field: CustomField, update: CustomFieldUpdate) {
        var edited = false

        let updatedField = field.update(from: update)
        if let index = extraPersonalDetails.firstIndex(where: { $0.id == field.id }) {
            edited = true
            extraPersonalDetails[index] = updatedField
        }

        if !edited, let index = extraAddressDetails.firstIndex(where: { $0.id == field.id }) {
            edited = true
            extraAddressDetails[index] = updatedField
        }

        if !edited, let index = extraContactDetails.firstIndex(where: { $0.id == field.id }) {
            edited = true
            extraContactDetails[index] = updatedField
        }

        if !edited, let index = extraWorkDetails.firstIndex(where: { $0.id == field.id }) {
            edited = true
            extraWorkDetails[index] = updatedField
        }

        if edited {
            recentlyAddedOrEditedField = updatedField
        } else {
            super.editCustomField(field, update: update)
        }
    }

    override func bindValues() {
        switch mode {
        case let .clone(itemContent), let .edit(itemContent):
            guard case let .identity(data) = itemContent.contentData else { return }

            for item in BaseIdentitySection.allCases {
                let shouldBeExpanded = data.sectionShouldBeExpanded(for: item)
                let section = item.createEditIdentitySection.copy(isCollapsed: !shouldBeExpanded)
                sections.append(section)
            }

            title = itemContent.name
            fullName = data.fullName
            email = data.email
            phoneNumber = data.phoneNumber
            firstName = .init(value: data.firstName)
            middleName = .init(value: data.middleName)
            lastName = .init(value: data.lastName)
            birthdate = .init(value: data.birthdate)
            gender = .init(value: data.gender)
            extraPersonalDetails = data.extraPersonalDetails
            organization = data.organization
            streetAddress = data.streetAddress
            zipOrPostalCode = data.zipOrPostalCode
            city = data.city
            stateOrProvince = data.stateOrProvince
            countryOrRegion = data.countryOrRegion
            floor = .init(value: data.floor)
            county = .init(value: data.county)
            extraAddressDetails = data.extraAddressDetails
            socialSecurityNumber = data.socialSecurityNumber
            passportNumber = data.passportNumber
            licenseNumber = data.licenseNumber
            website = data.website
            xHandle = data.xHandle
            secondPhoneNumber = data.secondPhoneNumber
            linkedIn = .init(value: data.linkedIn)
            reddit = .init(value: data.reddit)
            facebook = .init(value: data.facebook)
            yahoo = .init(value: data.yahoo)
            instagram = .init(value: data.instagram)
            extraContactDetails = data.extraContactDetails
            company = data.company
            jobTitle = data.jobTitle
            personalWebsite = .init(value: data.personalWebsite)
            workPhoneNumber = .init(value: data.workPhoneNumber)
            workEmail = .init(value: data.workEmail)
            extraWorkDetails = data.extraWorkDetails
            customSections = data.extraSections
        case .create:
            addBaseSections()
        }
    }

    override func generateItemContent() async -> ItemContentProtobuf {
        let data = IdentityData(fullName: fullName,
                                email: email,
                                phoneNumber: phoneNumber,
                                firstName: firstName.value,
                                middleName: middleName.value,
                                lastName: lastName.value,
                                birthdate: birthdate.value,
                                gender: gender.value,
                                extraPersonalDetails: extraPersonalDetails,
                                organization: organization,
                                streetAddress: streetAddress,
                                zipOrPostalCode: zipOrPostalCode,
                                city: city,
                                stateOrProvince: stateOrProvince,
                                countryOrRegion: countryOrRegion,
                                floor: floor.value,
                                county: county.value,
                                extraAddressDetails: extraAddressDetails,
                                socialSecurityNumber: socialSecurityNumber,
                                passportNumber: passportNumber,
                                licenseNumber: licenseNumber,
                                website: website,
                                xHandle: xHandle,
                                secondPhoneNumber: secondPhoneNumber,
                                linkedIn: linkedIn.value,
                                reddit: reddit.value,
                                facebook: facebook.value,
                                yahoo: yahoo.value,
                                instagram: instagram.value,
                                extraContactDetails: extraContactDetails,
                                company: company,
                                jobTitle: jobTitle,
                                personalWebsite: personalWebsite.value,
                                workPhoneNumber: workPhoneNumber.value,
                                workEmail: workEmail.value,
                                extraWorkDetails: extraWorkDetails,
                                extraSections: customSections)
        return .init(name: title,
                     note: "",
                     itemUuid: UUID().uuidString,
                     data: .identity(data),
                     customFields: [])
    }
}

// MARK: - Utils

extension CreateEditIdentityViewModel {
    func toggleCollapsingSection(_ sectionToToggle: CreateEditIdentitySection) {
        sections = sections.map { section in
            guard sectionToToggle.id == section.id else {
                return section
            }
            return section.copy(isCollapsed: !section.isCollapsed)
        }
    }
}

private extension CreateEditIdentityViewModel {
    func addBaseSections() {
        for item in BaseIdentitySection.allCases {
            sections.append(item.createEditIdentitySection)
        }
    }
}

private extension IdentityData {
    typealias SectionElements = Collection & Equatable

    var contactSection: [any SectionElements] {
        [
            socialSecurityNumber,
            passportNumber,
            licenseNumber,
            website,
            xHandle,
            secondPhoneNumber,
            linkedIn,
            reddit,
            facebook,
            yahoo,
            instagram,
            extraContactDetails
        ]
    }

    var workSection: [any SectionElements] {
        [
            company,
            jobTitle,
            personalWebsite,
            workPhoneNumber,
            workEmail,
            extraWorkDetails
        ]
    }

    func sectionShouldBeExpanded(for sectionType: BaseIdentitySection) -> Bool {
        switch sectionType {
        case .address, .personalDetails:
            true
        case .workDetail:
            workSection.contains { !$0.isEmpty }
        case .contact:
            contactSection.contains { !$0.isEmpty }
        }
    }
}
