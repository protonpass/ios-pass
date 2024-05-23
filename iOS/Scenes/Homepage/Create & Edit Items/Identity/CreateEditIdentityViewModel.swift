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

    var identitySectionHeaderKey: IdentitySectionHeaderKey {
        IdentitySectionHeaderKey(title: rawValue)
    }
}

@Copyable
struct IdentitySection {
    let id: String
    let title: String
    let order: Int

    let cells: Set<IdentityCellContent>
}

struct IdentitySectionHeaderKey: Hashable, Comparable, Identifiable {
    let title: String

    var id: String {
        title
    }

    static func < (lhs: IdentitySectionHeaderKey, rhs: IdentitySectionHeaderKey) -> Bool {
        lhs.title < rhs.title
    }
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
    @Published var fullName = ""

    @Published var sections = [IdentitySectionHeaderKey: IdentitySection]()
    @Published var collapsedSections = Set<IdentitySectionHeaderKey>()

    override init(mode: ItemMode,
                  upgradeChecker: any UpgradeCheckerProtocol,
                  vaults: [Vault]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)
        setUp()
    }

    override func itemContentType() -> ItemContentType { .identity }

    func udpdateCellContent(newValue: String, sectionKey: IdentitySectionHeaderKey, contentId: String) {
        guard let cellsContent = sections[sectionKey],
              let newContent = cellsContent.cells.first(where: { $0.id == contentId })?.copy(value: newValue)
        else {
            return
        }
        var cells = cellsContent.cells
        cells.update(with: newContent)
        sections[sectionKey] = cellsContent.copy(cells: cells)
    }
}

private extension CreateEditIdentityViewModel {
    func setUp() {
        mockData()
        addDefaultCollapsedSection()
    }

    func addDefaultCollapsedSection() {
        collapsedSections.insert(BaseIdentitySection.contact.identitySectionHeaderKey)
        collapsedSections.insert(BaseIdentitySection.workDetail.identitySectionHeaderKey)
    }

    func mockData() {
        for (index, key) in BaseIdentitySection.allCases.enumerated() {
            let sectionkey = key.identitySectionHeaderKey
            sections[sectionkey] = IdentitySection(id: UUID().uuidString,
                                                   title: key.rawValue,
                                                   order: index,
                                                   cells: [IdentityCellContent(id: UUID().uuidString,
                                                                               sectionid: sectionkey.id,
                                                                               title: "First name", value: "")])
        }
    }
}

extension [IdentitySectionHeaderKey: IdentitySection] {
    var sortedKey: [IdentitySectionHeaderKey] {
        self.keys.sorted {
            (self[$0]?.order ?? 0) < (self[$1]?.order ?? 0)
        }
    }
}
