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
import Factory
import Foundation
import Macro

enum BaseIdentitySection: String, CaseIterable {
    case personalDetails = "Personal details"
    case address = "Address details"
    case contact = "Contact details"
    case workDetail = "Work details"
    case custom

    var createEditIdentitySection: CreateEditIdentitySection {
        CreateEditIdentitySection(id: rawValue,
                                  title: title,
                                  type: self,
                                  isCollapsed: self == .contact || self == .workDetail,
                                  isCustom: false,
                                  content: [])
    }

    private var title: String {
        switch self {
        case .personalDetails:
            #localized("Personal details")
        case .address:
            #localized("Address details")
        case .contact:
            #localized("Contact details")
        case .workDetail:
            #localized("Work details")
        case .custom:
            ""
        }
    }
}

extension CustomSection {
    var createEditIdentitySection: CreateEditIdentitySection {
        CreateEditIdentitySection(title: title,
                                  type: .custom,
                                  isCollapsed: true,
                                  isCustom: true,
                                  content: content.map { CustomFieldUiModel(customField: $0) })
    }
}

@Copyable
struct CreateEditIdentitySection: Hashable, Identifiable {
    var id: String = UUID().uuidString
    let title: String
    let type: BaseIdentitySection
    let isCollapsed: Bool
    let isCustom: Bool
    var content: [CustomFieldUiModel]

    static func baseCustomSection(title: String) -> CreateEditIdentitySection {
        CreateEditIdentitySection(title: title,
                                  type: .custom,
                                  isCollapsed: false,
                                  isCustom: true,
                                  content: [])
    }
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
    @Published var title = ""

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
    @Published var extraPersonalDetails: [CustomFieldUiModel] = []

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
    @Published var extraAddressDetails: [CustomFieldUiModel] = []

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
    @Published var extraContactDetails: [CustomFieldUiModel] = []

    /// Work details
    /// Shown
    @Published var company = ""
    @Published var jobTitle = ""

    /// Additional
    @Published var personalWebsite: HiddenStringValue = .default
    @Published var workPhoneNumber: HiddenStringValue = .default
    @Published var workEmail: HiddenStringValue = .default
    @Published var extraWorkDetails: [CustomFieldUiModel] = []

    @Published var sections = [CreateEditIdentitySection]()

    private var customFieldSection: CreateEditIdentitySection?
    @Published var customSectionTitle = ""

    override var isSaveable: Bool {
        super.isSaveable && !title.isEmpty
    }

    private(set) var selectedCustomSection: CreateEditIdentitySection?

    override var itemContentType: ItemContentType { .identity }

    override func customFieldEdited(_ uiModel: CustomFieldUiModel, newTitle: String) {
        sections = sections.map { section in
            guard let index = getIndex(section, uiModel) else {
                return section
            }

            recentlyAddedOrEditedField = uiModel
            switch section.type {
            case .address:
                extraAddressDetails[index] = uiModel.update(title: newTitle)
                return section

            case .personalDetails:
                extraPersonalDetails[index] = uiModel.update(title: newTitle)
                return section

            case .workDetail:
                extraWorkDetails[index] = uiModel.update(title: newTitle)
                return section

            case .contact:
                extraContactDetails[index] = uiModel.update(title: newTitle)
                return section

            case .custom:
                var newCustoms = section.content
                newCustoms[index] = uiModel.update(title: newTitle)
                return section.copy(content: newCustoms)
            }
        }
    }

    override func customFieldEdited(_ uiModel: CustomFieldUiModel, content: String) {
        sections = sections.map { section in
            guard let index = getIndex(section, uiModel) else {
                return section
            }
            recentlyAddedOrEditedField = uiModel
            switch section.type {
            case .address:
                extraAddressDetails[index] = uiModel.update(content: content)
                return section
            case .personalDetails:
                extraPersonalDetails[index] = uiModel.update(content: content)
                return section
            case .workDetail:
                extraWorkDetails[index] = uiModel.update(content: content)
                return section
            case .contact:
                extraContactDetails[index] = uiModel.update(content: content)
                return section
            case .custom:
                var newCustoms = section.content
                newCustoms[index] = uiModel.update(content: content)
                return section.copy(content: newCustoms)
            }
        }
    }

    override func customFieldAdded(_ customField: CustomField) {
        sections = sections.map { section in
            guard let customFieldSection,
                  customFieldSection.id == section.id else {
                return section
            }

            var newCustoms = section.content
            let uiModel = CustomFieldUiModel(customField: customField)
            recentlyAddedOrEditedField = uiModel

            switch section.type {
            case .address:
                extraAddressDetails.append(uiModel)
                return section

            case .personalDetails:
                extraPersonalDetails.append(uiModel)
                return section

            case .workDetail:
                extraWorkDetails.append(uiModel)
                return section

            case .contact:
                extraContactDetails.append(uiModel)
                return section

            case .custom:
                newCustoms.append(uiModel)
            }

            return section.copy(content: newCustoms)
        }
    }

    override func bindValues() {
        switch mode {
        case let .clone(itemContent), let .edit(itemContent):
            guard case let .identity(data) = itemContent.contentData else { return }

            for item in BaseIdentitySection.allCases where item != .custom {
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
            extraPersonalDetails = data.extraPersonalDetails.map { CustomFieldUiModel(customField: $0) }
            organization = data.organization
            streetAddress = data.streetAddress
            zipOrPostalCode = data.zipOrPostalCode
            city = data.city
            stateOrProvince = data.stateOrProvince
            countryOrRegion = data.countryOrRegion
            floor = .init(value: data.floor)
            county = .init(value: data.county)
            extraAddressDetails = data.extraAddressDetails.map { CustomFieldUiModel(customField: $0) }
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
            extraContactDetails = data.extraContactDetails.map { CustomFieldUiModel(customField: $0) }
            company = data.company
            jobTitle = data.jobTitle
            personalWebsite = .init(value: data.personalWebsite)
            workPhoneNumber = .init(value: data.workPhoneNumber)
            workEmail = .init(value: data.workEmail)
            extraWorkDetails = data.extraWorkDetails.map { CustomFieldUiModel(customField: $0) }
            sections.append(contentsOf: data.extraSections.toCreateEditIdentitySections)
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
                                extraPersonalDetails: extraPersonalDetails.map(\.customField),
                                organization: organization,
                                streetAddress: streetAddress,
                                zipOrPostalCode: zipOrPostalCode,
                                city: city,
                                stateOrProvince: stateOrProvince,
                                countryOrRegion: countryOrRegion,
                                floor: floor.value,
                                county: county.value,
                                extraAddressDetails: extraAddressDetails.map(\.customField),
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
                                extraContactDetails: extraContactDetails.map(\.customField),
                                company: company,
                                jobTitle: jobTitle,
                                personalWebsite: personalWebsite.value,
                                workPhoneNumber: workPhoneNumber.value,
                                workEmail: workEmail.value,
                                extraWorkDetails: extraWorkDetails.map(\.customField),
                                extraSections: sections.filterToCustomSections)
        return .init(name: title,
                     note: "",
                     itemUuid: UUID().uuidString,
                     data: .identity(data),
                     customFields: [])
    }
}

// MARK: - Utils

extension CreateEditIdentityViewModel {
    func setSelectedSection(section: CreateEditIdentitySection) {
        selectedCustomSection = section
    }

    func deleteCustomSection() {
        guard let sectionToDelete = selectedCustomSection else {
            return
        }

        sections = sections.removing(sectionToDelete)
        selectedCustomSection = nil
    }

    func reset() {
        customSectionTitle = ""
        selectedCustomSection = nil
    }

    func addCustomSection() {
        guard !customSectionTitle.isEmpty else {
            return
        }
        let newSection = CreateEditIdentitySection.baseCustomSection(title: customSectionTitle)
        sections.append(newSection)
        customSectionTitle = ""
    }

    func modifyCustomSectionName() {
        guard !customSectionTitle.isEmpty, let sectionToModify = selectedCustomSection else {
            return
        }
        sections = sections.map { section in
            guard sectionToModify.id == section.id else {
                return section
            }
            return section.copy(title: customSectionTitle)
        }
        customSectionTitle = ""
    }

    func getIndex(_ section: CreateEditIdentitySection, _ uiModel: CustomFieldUiModel) -> Int? {
        switch section.type {
        case .address:
            extraAddressDetails.firstIndex(where: { $0.id == uiModel.id })

        case .personalDetails:
            extraPersonalDetails.firstIndex(where: { $0.id == uiModel.id })

        case .workDetail:
            extraWorkDetails.firstIndex(where: { $0.id == uiModel.id })

        case .contact:
            extraContactDetails.firstIndex(where: { $0.id == uiModel.id })

        case .custom:
            section.content.firstIndex(where: { $0.id == uiModel.id })
        }
    }

    func toggleCollapsingSection(_ sectionToToggle: CreateEditIdentitySection) {
        sections = sections.map { section in
            guard sectionToToggle.id == section.id else {
                return section
            }
            return section.copy(isCollapsed: !section.isCollapsed)
        }
    }

    func addCustomField(to section: CreateEditIdentitySection) {
        customFieldSection = section
        delegate?.createEditItemViewModelWantsToAddCustomField(delegate: self, shouldDisplayTotp: false)
    }
}

private extension CreateEditIdentityViewModel {
    func addBaseSections() {
        for item in BaseIdentitySection.allCases where item != .custom {
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
        default:
            false
        }
    }
}

private extension [CustomSection] {
    var toCreateEditIdentitySections: [CreateEditIdentitySection] {
        self.map(\.createEditIdentitySection)
    }
}

private extension [CreateEditIdentitySection] {
    var filterToCustomSections: [CustomSection] {
        self.compactMap { section in
            guard section.isCustom else {
                return nil
            }
            return CustomSection(title: section.title, content: section.content.map(\.customField))
        }
    }
}
