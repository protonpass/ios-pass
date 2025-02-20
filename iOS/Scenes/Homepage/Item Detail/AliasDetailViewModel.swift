//
// AliasDetailViewModel.swift
// Proton Pass - Created on 15/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Client
import Combine
import Core
import Entities
import Factory
import Foundation
import Macro

@MainActor
final class AliasDetailViewModel: BaseItemDetailViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var aliasEmail = ""
    @Published private(set) var name = ""
    @Published private(set) var note = ""
    @Published private(set) var aliasInfos: Alias?
    @Published private(set) var contacts: PaginatedAliasContacts?
    @Published private(set) var error: (any Error)?
    @Published private(set) var aliasEnabled = false
    @Published private(set) var togglingAliasStatus = false
    @Published private(set) var showContactsTip = false

    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository

    private var task: Task<Void, Never>?

    var aliasDiscoveryActive: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passAliasDiscovery)
    }

    // One could be an editor of an alias but not the owner
    // Only owner can see and edit mailboxes
    var isAliasOwner: Bool {
        aliasInfos?.mailboxes.isEmpty == false
    }

    var showMailboxesRow: Bool {
        if let aliasInfos {
            !aliasInfos.mailboxes.isEmpty
        } else {
            true
        }
    }

    private var aliasDiscovery: AliasDiscovery {
        preferencesManager.sharedPreferences.unwrapped().aliasDiscovery
    }

    override func bindValues() {
        super.bindValues()
        aliasEmail = itemContent.item.aliasEmail ?? ""
        aliasEnabled = itemContent.item.isAliasEnabled
        if case .alias = itemContent.contentData {
            name = itemContent.name
            note = itemContent.note
        } else {
            fatalError("Expecting alias type")
        }

        showContactsTip = !aliasDiscovery.contains(.contacts)

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
                    await loadContact()
                }
            }
            .store(in: &cancellables)
    }

    func getAlias() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let alias =
                    try await aliasRepository.getAliasDetails(shareId: itemContent.shareId,
                                                              itemId: itemContent.item.itemID)
                aliasEmail = alias.email
                aliasInfos = alias
                aliasEnabled = itemContent.item.isAliasEnabled
                logger.info("Get alias detail successfully \(itemContent.debugDescription)")
            } catch {
                logger.error(error)
                self.error = error
            }
        }
    }

    func loadContact() async {
        guard isAllowedToEdit else { return }
        do {
            let userId = try await userManager.getActiveUserId()
            contacts = try await aliasRepository.getContacts(userId: userId,
                                                             shareId: itemContent.shareId,
                                                             itemId: itemContent.item.itemID,
                                                             lastContactId: nil)
        } catch {
            if let apiError = error.asPassApiError,
               apiError == .notAllowed || apiError == .itemDoesNotExist {
                // Happen when alias is not created by this user so we ignore this error
                return
            }
            handle(error)
        }
    }

    func toggleAliasState() {
        setAliasStatus(enabled: !aliasEnabled)
    }

    override func disableAlias() {
        setAliasStatus(enabled: false)
    }

    override func refresh() {
        error = nil
        super.refresh()
        getAlias()
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            await loadContact()
        }
    }

    func copyAliasEmail() {
        copyToClipboard(text: aliasEmail, message: #localized("Alias copied"))
    }

    func copyMailboxEmail(_ email: String) {
        copyToClipboard(text: email, message: #localized("Email address copied"))
    }

    func getContactsInfos() -> ContactsInfos? {
        guard let contacts, let aliasInfos else { return nil }
        return ContactsInfos(itemId: itemContent.itemId,
                             shareId: itemContent.shareId,
                             alias: aliasInfos,
                             contacts: contacts)
    }

    func dismissContactsTip() {
        Task { [weak self] in
            guard let self else { return }
            var aliasDiscovery = aliasDiscovery
            guard !aliasDiscovery.contains(.contacts) else { return }
            aliasDiscovery.flip(.contacts)
            do {
                try await preferencesManager.updateSharedPreferences(\.aliasDiscovery,
                                                                     value: aliasDiscovery)
                showContactsTip = false
            } catch {
                handle(error)
            }
        }
    }
}

private extension AliasDetailViewModel {
    func setAliasStatus(enabled: Bool) {
        Task { [weak self] in
            guard let self else { return }
            defer { togglingAliasStatus = false }
            do {
                togglingAliasStatus = true
                let userId = try await userManager.getActiveUserId()
                try await itemRepository.changeAliasStatus(userId: userId,
                                                           items: [itemContent],
                                                           enabled: enabled)
                let message = enabled ? #localized("Alias enabled") : #localized("Alias disabled")
                router.display(element: .infosMessage(message, config: .refresh))
                logger.trace("Successfully updated the alias status of \(enabled)")
                aliasEnabled = enabled
            } catch {
                logger.error(error)
                self.error = error
            }
        }
    }
}
