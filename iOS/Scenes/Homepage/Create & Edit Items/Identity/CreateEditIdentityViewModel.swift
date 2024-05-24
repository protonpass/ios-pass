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
import Core
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

//    var identitySectionHeaderKey: IdentitySectionHeaderKey {
//        IdentitySectionHeaderKey(title: rawValue)
//    }

    var createEditIdentitySection: CreateEditIdentitySection {
        CreateEditIdentitySection(id: rawValue,
                                  title: rawValue,
                                  type: self,
                                  isCollapsed: self == .contact || self == .workDetail,
                                  isCustom: false,
                                  content: nil)
    }
}

extension CustomSection {
//    var identitySectionHeaderKey: IdentitySectionHeaderKey {
//        IdentitySectionHeaderKey(title: title)
//    }

    var createEditIdentitySection: CreateEditIdentitySection {
        CreateEditIdentitySection(id: UUID().uuidString,
                                  title: title,
                                  type: .custom,
                                  isCollapsed: true,
                                  isCustom: true,
                                  content: content.map { CustomFieldUiModel(customField: $0) })
    }
}

// @Copyable
// struct IdentitySection {
//    let id: String
//    let title: String
//    let order: Int
//
////    let cells: Set<IdentityCellContent>
// }

// struct IdentitySectionHeaderKey: Hashable, Comparable, Identifiable {
//    let title: String
//
//    var id: Int {
//        hashValue
//    }
//
//    static func < (lhs: IdentitySectionHeaderKey, rhs: IdentitySectionHeaderKey) -> Bool {
//        lhs.title < rhs.title
//    }
// }

@Copyable
struct CreateEditIdentitySection: Hashable, Identifiable {
    let id: String
    let title: String
    let type: BaseIdentitySection
    let isCollapsed: Bool
    let isCustom: Bool
    let content: [CustomFieldUiModel]?
}

@Copyable
struct IdentityCellContent: Hashable {
    let id: String
    let sectionid: String
    let title: String
//    let type: Int
    let value: String
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
    @Published var linkedin = (value: "", shouldShow: false)
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

    /// Extra sections
    @Published var extraSections: [CustomSection] = []
    @Published var sections = [CreateEditIdentitySection]()

    private var customFieldSection: CreateEditIdentitySection?
//    @Published var sections = [IdentitySectionHeaderKey: IdentitySection]()
//    @Published var collapsedSections = Set<IdentitySectionHeaderKey>()

    override init(mode: ItemMode,
                  upgradeChecker: any UpgradeCheckerProtocol,
                  vaults: [Vault]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)
        setUp()
    }

    // TODO: Bind values

    override func itemContentType() -> ItemContentType { .identity }

//    func udpdateCellContent(newValue: String, sectionKey: IdentitySectionHeaderKey, contentId: String) {
    ////        guard let cellsContent = sections[sectionKey],
    ////              let newContent = cellsContent.cells.first(where: { $0.id == contentId })?.copy(value:
    /// newValue)
    ////        else {
    ////            return
    ////        }
    ////        var cells = cellsContent.cells
    ////        cells.update(with: newContent)
    ////        sections[sectionKey] = cellsContent.copy(cells: cells)
//    }

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

    override func customFieldEdited(_ uiModel: CustomFieldUiModel, newTitle: String) {
        sections = sections.map { section in
            guard
//                let customFieldSection,
//                  customFieldSection.id == section.id,
                let index = getIndex(section, uiModel) else {
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
                newCustoms?[index] = uiModel.update(title: newTitle)
                return section.copy(content: newCustoms)
            }
        }
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
            section.content?.firstIndex(where: { $0.id == uiModel.id })
        }
    }

    override func customFieldEdited(_ uiModel: CustomFieldUiModel, content: String) {
        sections = sections.map { section in
            guard
//                let customFieldSection,
//                  customFieldSection.id == section.id,
                let index = getIndex(section, uiModel) else {
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
                newCustoms?[index] = uiModel.update(content: content)
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
                newCustoms?.append(uiModel)
            }

            return section.copy(content: newCustoms)
        }
    }
}

private extension CreateEditIdentityViewModel {
    func setUp() {
//        mockData()
        addSections()
//        addDefaultCollapsedSection()
    }

    func addSections() {
        for item in BaseIdentitySection.allCases {
            sections.append(item.createEditIdentitySection)
        }

        for extraSection in extraSections {
            sections.append(extraSection.createEditIdentitySection)
        }
    }

//    func addDefaultCollapsedSection() {
//        collapsedSections.insert(BaseIdentitySection.contact.identitySectionHeaderKey)
//        collapsedSections.insert(BaseIdentitySection.workDetail.identitySectionHeaderKey)
//        for section in extraSections {
//            collapsedSections.insert(section.identitySectionHeaderKey)
//        }
//    }

//    func mockData() {
//        for (index, key) in BaseIdentitySection.allCases.enumerated() {
//            let sectionkey = key.identitySectionHeaderKey
//            sections[sectionkey] = IdentitySection(id: UUID().uuidString,
//                                                   title: key.rawValue,
//                                                   order: index,
//                                                   cells: [IdentityCellContent(id: UUID().uuidString,
//                                                                               sectionid: sectionkey.id,
//                                                                               title: "First name", value: "")])
//        }
//    }
}

// extension [IdentitySectionHeaderKey: IdentitySection] {
//    var sortedKey: [IdentitySectionHeaderKey] {
//        self.keys.sorted {
//            (self[$0]?.order ?? 0) < (self[$1]?.order ?? 0)
//        }
//    }
// }
