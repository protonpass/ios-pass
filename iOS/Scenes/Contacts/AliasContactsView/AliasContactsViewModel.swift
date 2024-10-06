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
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedToolingContainer.logger) private var logger

    private var cancellables = Set<AnyCancellable>()

    var itemIds: IDs {
        IDs(shareId: item.shareId, itemId: item.itemId)
    }

    init(item: ItemContent, contacts: GetAliasContactsResponse) {
        self.contacts = contacts
        self.item = item
        setUp()
//        parseContacts()
    }

    func copyContact(_ contact: AliasContact) {
        router.action(.copyToClipboard(text: contact.email, message: #localized("Contact copied")))
    }

    // https://stackoverflow.com/questions/71260260/what-method-do-i-call-to-open-the-ios-mail-app-with-swiftui
    func openMail(emailTo: String) {
        // TODO: need to add the name
        if let url = URL(string: "mailto:\("Eric plop")<\(emailTo)>"),

           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func delete(contact: AliasContact) {
        //TODO: add deletion for contact
    }

    func toggleContactState(_ contact: AliasContact) {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let userId = try await userManager.getActiveUserId()
                _ = try await aliasRepository.updateContact(userId: userId,
                                                            shareId: item.shareId,
                                                            itemId: item.itemId,
                                                            contactId: "\(contact.ID)",
                                                            blocked: !contact.blocked)
                try await reloadContact()
            } catch {
                handle(error)
            }
        }
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

        aliasRepository.contactsUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else {
                    return
                }
                Task { [weak self] in
                    guard let self else {
                        return
                    }
                    try? await reloadContact()
                }
            }
            .store(in: &cancellables)
    }

    func reloadContact() async throws {
        let userId = try await userManager.getActiveUserId()
        contacts = try await aliasRepository.getContacts(userId: userId,
                                                         shareId: item.shareId,
                                                         itemId: item.itemId,
                                                         lastContactId: nil)
        parseContacts()
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

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
