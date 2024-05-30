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

import Client
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
                                  title: rawValue,
                                  type: self,
                                  isCollapsed: self == .contact || self == .workDetail,
                                  isCustom: false,
                                  content: [])
    }
}

extension CustomSection {
    var createEditIdentitySection: CreateEditIdentitySection {
        CreateEditIdentitySection(id: UUID().uuidString,
                                  title: title,
                                  type: .custom,
                                  isCollapsed: true,
                                  isCustom: true,
                                  content: content.map { CustomFieldUiModel(customField: $0) })
    }
}

@Copyable
struct CreateEditIdentitySection: Hashable, Identifiable {
    let id: String
    let title: String
    let type: BaseIdentitySection
    let isCollapsed: Bool
    let isCustom: Bool
    var content: [CustomFieldUiModel]

    static func baseCustomSection(title: String) -> CreateEditIdentitySection {
        CreateEditIdentitySection(id: UUID().uuidString,
                                  title: title,
                                  type: .custom,
                                  isCollapsed: true,
                                  isCustom: true,
                                  content: [])
    }
}

@MainActor
final class CreateEditIdentityViewModel: BaseCreateEditItemViewModel, ObservableObject, Sendable {
    @Published var title = ""

    /// Personal details
    /// Shown
    @Published var fullName = ""
    @Published var email = ""
    @Published var phoneNumber = ""

    /// Additional
    @Published var firstName = (value: "", shouldShow: false)
    @Published var middleName = (value: "", shouldShow: false)
    @Published var lastName = (value: "", shouldShow: false)
    @Published var birthdate = (value: "", shouldShow: false)
    @Published var gender = (value: "", shouldShow: false)
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
    @Published var floor = (value: "", shouldShow: false)
    @Published var county = (value: "", shouldShow: false)
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
    @Published var linkedIn = (value: "", shouldShow: false)
    @Published var reddit = (value: "", shouldShow: false)
    @Published var facebook = (value: "", shouldShow: false)
    @Published var yahoo = (value: "", shouldShow: false)
    @Published var instagram = (value: "", shouldShow: false)
    @Published var extraContactDetails: [CustomFieldUiModel] = []

    /// Work details
    /// Shown
    @Published var company = ""
    @Published var jobTitle = ""

    /// Additional
    @Published var personalWebsite = (value: "", shouldShow: false)
    @Published var workPhoneNumber = (value: "", shouldShow: false)
    @Published var workEmail = (value: "", shouldShow: false)
    @Published var extraWorkDetails: [CustomFieldUiModel] = []

    @Published var sections = [CreateEditIdentitySection]()

    private var customFieldSection: CreateEditIdentitySection?
    @Published var customSectionTitle = ""

    private(set) var sectionToDelete: CreateEditIdentitySection?

    override init(mode: ItemMode,
                  upgradeChecker: any UpgradeCheckerProtocol,
                  vaults: [Vault]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)
    }

    override func itemContentType() -> ItemContentType { .identity }

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
                sections.append(item.createEditIdentitySection)
            }

            title = itemContent.name
            fullName = data.fullName
            email = data.email
            phoneNumber = data.phoneNumber
            firstName = (value: data.firstName, shouldShow: !data.firstName.isEmpty)
            middleName = (value: data.middleName, shouldShow: !data.middleName.isEmpty)
            lastName = (value: data.lastName, shouldShow: !data.lastName.isEmpty)
            birthdate = (value: data.birthdate, shouldShow: !data.birthdate.isEmpty)
            gender = (value: data.gender, shouldShow: !data.gender.isEmpty)
            extraPersonalDetails = data.extraPersonalDetails.map { CustomFieldUiModel(customField: $0) }
            organization = data.organization
            streetAddress = data.streetAddress
            zipOrPostalCode = data.zipOrPostalCode
            city = data.city
            stateOrProvince = data.stateOrProvince
            countryOrRegion = data.countryOrRegion
            floor = (value: data.floor, shouldShow: !data.floor.isEmpty)
            county = (value: data.county, shouldShow: !data.county.isEmpty)
            extraAddressDetails = data.extraAddressDetails.map { CustomFieldUiModel(customField: $0) }
            socialSecurityNumber = data.socialSecurityNumber
            passportNumber = data.passportNumber
            licenseNumber = data.licenseNumber
            website = data.website
            xHandle = data.xHandle
            secondPhoneNumber = data.secondPhoneNumber
            linkedIn = (value: data.linkedIn, shouldShow: !data.linkedIn.isEmpty)
            reddit = (value: data.reddit, shouldShow: !data.reddit.isEmpty)
            facebook = (value: data.facebook, shouldShow: !data.facebook.isEmpty)
            yahoo = (value: data.yahoo, shouldShow: !data.yahoo.isEmpty)
            instagram = (value: data.instagram, shouldShow: !data.instagram.isEmpty)
            extraContactDetails = data.extraContactDetails.map { CustomFieldUiModel(customField: $0) }
            company = data.company
            jobTitle = data.jobTitle

            personalWebsite = (value: data.personalWebsite, shouldShow: !data.personalWebsite.isEmpty)
            workPhoneNumber = (value: data.workPhoneNumber, shouldShow: !data.workPhoneNumber.isEmpty)
            workEmail = (value: data.workEmail, shouldShow: !data.workEmail.isEmpty)
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
    func setSectionToDelete(sectionToDelete: CreateEditIdentitySection) {
        self.sectionToDelete = sectionToDelete
    }

    func deleteCustomSection() {
        guard let sectionToDelete else {
            return
        }

        sections = sections.removing(sectionToDelete)
        self.sectionToDelete = nil
    }

    func reset() {
        customSectionTitle = ""
        sectionToDelete = nil
    }

    func addCustomSection() {
        guard !customSectionTitle.isEmpty else {
            return
        }
        let newSection = CreateEditIdentitySection.baseCustomSection(title: customSectionTitle)
        sections.append(newSection)
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

    func toggleCollapsingSection(sectionToToggle: CreateEditIdentitySection) {
        sections = sections.map { section in
            guard sectionToToggle.id == section.id else {
                return section
            }
            return section.copy(isCollapsed: !section.isCollapsed)
        }
    }

    func addCustomField(to section: CreateEditIdentitySection) {
        customFieldSection = section
        delegate?.createEditItemViewModelWantsToAddCustomField(delegate: self)
    }
}

private extension CreateEditIdentityViewModel {
    func addBaseSections() {
        for item in BaseIdentitySection.allCases where item != .custom {
            sections.append(item.createEditIdentitySection)
        }
    }
}

extension [CustomSection] {
    var toCreateEditIdentitySections: [CreateEditIdentitySection] {
        self.map(\.createEditIdentitySection)
    }
}

extension [CreateEditIdentitySection] {
    var filterToCustomSections: [CustomSection] {
        self.compactMap { section in
            guard section.isCustom else {
                return nil
            }
            return CustomSection(title: section.title, content: section.content.map(\.customField))
        }
    }
}
