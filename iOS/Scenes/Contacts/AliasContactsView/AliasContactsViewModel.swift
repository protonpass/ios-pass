//
//
// AliasContactsViewModel.swift
// Proton Pass - Created on 03/10/2024.
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

struct AliasContactsModel {
    let activeContacts: [AliasContact]
    let blockContacts: [AliasContact]

    static var `default`: AliasContactsModel {
        AliasContactsModel(activeContacts: [AliasContact(ID: 1, blocked: false, reverseAlias: true, email: true)],
                           blockContacts: [AliasContact(ID: 2, blocked: true, reverseAlias: false, email: false)])
    }
}

@MainActor
final class AliasContactsViewModel: ObservableObject, Sendable {
    @Published private(set) var showExplanation = false
    @Published private(set) var contactsInfos = AliasContactsModel.default

    var hasNoContact: Bool {
        contacts.contacts.isEmpty
    }

    private var contacts: GetAliasContactsResponse
    private let item: ItemContent

    @LazyInjected(\SharedToolingContainer.preferencesManager) private var preferencesManager

    var itemIds: IDs {
        IDs(shareId: item.shareId, itemId: item.itemId)
    }

    init(item: ItemContent, contacts: GetAliasContactsResponse) {
        self.contacts = contacts
        self.item = item
        setUp()
    }
}

private extension AliasContactsViewModel {
    func setUp() {
        if !preferencesManager.appPreferences.unwrapped().hasVisitedContactPage {
            Task { [weak self] in
                guard let self else { return }
                try? await preferencesManager.updateAppPreferences(\.hasVisitedContactPage, value: true)
                showExplanation = true
            }
        }
//        parseContacts()
    }

    func parseContacts() {
        var activeContacts: [AliasContact] = []
        var blockContacts: [AliasContact] = []

        for contact in contacts.contacts {
            if contact.blocked {
                blockContacts.append(contact)
            } else {
                activeContacts.append(contact)
            }
        }

        contactsInfos = AliasContactsModel(activeContacts: activeContacts, blockContacts: blockContacts)
    }
}
