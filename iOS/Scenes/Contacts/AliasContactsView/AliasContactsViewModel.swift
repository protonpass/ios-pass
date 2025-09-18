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
import DesignSystem
import Entities
import FactoryKit
import Foundation
import Macro
import Screens
import UIKit

struct AliasContactsModel: Sendable, Hashable {
    let activeContacts: [AliasContact]
    let blockContacts: [AliasContact]

    var isEmpty: Bool {
        activeContacts.isEmpty && blockContacts.isEmpty
    }

    init(contacts: [AliasContact]) {
        var activeContacts: [AliasContact] = []
        var blockContacts: [AliasContact] = []

        for contact in contacts {
            if contact.blocked {
                blockContacts.append(contact)
            } else {
                activeContacts.append(contact)
            }
        }
        self.activeContacts = activeContacts
        self.blockContacts = blockContacts
    }

    init(activeContacts: [AliasContact], blockContacts: [AliasContact]) {
        self.activeContacts = activeContacts
        self.blockContacts = blockContacts
    }

    func update(with newContacts: [AliasContact]) -> AliasContactsModel {
        var activeContacts: [AliasContact] = activeContacts
        var blockContacts: [AliasContact] = blockContacts

        for contact in newContacts {
            if contact.blocked {
                blockContacts.append(contact)
            } else {
                activeContacts.append(contact)
            }
        }

        return AliasContactsModel(activeContacts: activeContacts, blockContacts: blockContacts)
    }
}

@MainActor
final class AliasContactsViewModel: ObservableObject {
    @Published var aliasName = ""
    @Published private(set) var displayName = ""
    @Published private(set) var showExplanation = false
    @Published private(set) var contactsInfos: AliasContactsModel
    @Published private(set) var loading = false
    @Published private(set) var loadingMoreContent = false

    var hasNoContact: Bool {
        contactsInfos.isEmpty
    }

    private var previousName = ""
    private(set) var alias: Alias
    private let infos: ContactsInfos
    private var canFetchMoreContact: Bool

    @Published private(set) var plan: Plan?

    @LazyInjected(\SharedToolingContainer.preferencesManager) private var preferencesManager
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedRepositoryContainer.accessRepository) private var accessRepository

    private var cancellables = Set<AnyCancellable>()

    var itemIds: IDs {
        IDs(shareId: infos.shareId, itemId: infos.itemId)
    }

    var isFreeUser: Bool {
        plan?.isFreeUser ?? true
    }

    var canManageAliases: Bool {
        plan?.manageAlias ?? false
    }

    init(infos: ContactsInfos) {
        contactsInfos = .init(contacts: infos.contacts.contacts)
        canFetchMoreContact = infos.contacts.contacts.count < infos.contacts.total
        self.infos = infos
        alias = infos.alias
        aliasName = alias.name ?? ""
        displayName = alias.displayName
        previousName = aliasName
        setUp()
    }

    func copyContact(_ contact: AliasContact) {
        router.action(.copyToClipboard(text: contact.reverseAlias, message: #localized("Contact copied")))
    }

    func sendEmail(to contact: AliasContact) {
        let url: URL? = if let namedUrl = contact.mailToNamedAddressUrl,
                           UIApplication.shared.canOpenURL(namedUrl) {
            namedUrl
        } else if let url = contact.mailToAddressUrl,
                  UIApplication.shared.canOpenURL(url) {
            url
        } else {
            nil
        }

        if let url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    func delete(contact: AliasContact) {
        Task { [weak self] in
            guard let self else {
                return
            }

            defer {
                loading = false
            }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                _ = try await aliasRepository.deleteContact(userId: userId,
                                                            shareId: infos.shareId,
                                                            itemId: infos.itemId,
                                                            contactId: "\(contact.ID)")
                try await reloadContact()
            } catch {
                handle(error)
            }
        }
    }

    func toggleContactState(_ contact: AliasContact) {
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                loading = false
            }
            do {
                loading = true

                let userId = try await userManager.getActiveUserId()
                _ = try await aliasRepository.updateContact(userId: userId,
                                                            shareId: infos.shareId,
                                                            itemId: infos.itemId,
                                                            contactId: "\(contact.ID)",
                                                            blocked: !contact.blocked)
            } catch {
                handle(error)
            }
        }
    }

    func upsell() {
        let config = UpsellingViewConfiguration(icon: PassIcon.passPlus,
                                                title: #localized("Manage your aliases"),
                                                description: UpsellEntry.aliasManagement.description,
                                                upsellElements: UpsellEntry.aliasManagement.upsellElements,
                                                ctaTitle: #localized("Get Pass Unlimited"))
        router.present(for: .upselling(config, .none))
    }

    func loadMore(lastContactId: Int?) {
        guard canFetchMoreContact else {
            return
        }
        loadingMoreContent = true
        Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                loadingMoreContent = false
            }
            do {
                try await reloadContact(lastContactId: lastContactId)
            } catch {
                handle(error)
            }
        }
    }
}

private extension AliasContactsViewModel {
    func setUp() {
        let access = accessRepository.access.value?.access
        plan = access?.plan

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
                    do {
                        try await reloadContact()
                    } catch {
                        handle(error)
                    }
                }
            }
            .store(in: &cancellables)

        accessRepository.access
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .compactMap(\.self)
            .sink { [weak self] updatedAccess in
                guard let self else {
                    return
                }
                plan = updatedAccess.access.plan
            }
            .store(in: &cancellables)
    }

    func reloadContact(lastContactId: Int? = nil) async throws {
        let userId = try await userManager.getActiveUserId()
        let contacts = try await aliasRepository.getContacts(userId: userId,
                                                             shareId: infos.shareId,
                                                             itemId: infos.itemId,
                                                             lastContactId: lastContactId)
        canFetchMoreContact = !contacts.contacts.isEmpty
        if lastContactId != nil {
            contactsInfos = contactsInfos.update(with: contacts.contacts)
        } else {
            contactsInfos = .init(contacts: contacts.contacts)
        }
    }

    func handle(_ error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
