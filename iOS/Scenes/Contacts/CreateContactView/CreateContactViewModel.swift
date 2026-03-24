//
//
// CreateContactViewModel.swift
// Proton Pass - Created on 04/10/2024.
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
import FactoryKit
import Foundation

@MainActor
@Observable
final class CreateContactViewModel {
    var email = ""
    var name = ""
    var error: (any Error)?
    private(set) var loading = false
    private(set) var createdContact: AliasContactLite?
    var showCopyAfterCreatingAlert = false

    var canCreate: Bool {
        email.isValidEmail()
    }

    @ObservationIgnored
    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository

    @ObservationIgnored
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager

    @ObservationIgnored
    @LazyInjected(\SharedToolingContainer.preferencesManager) private var preferencesManager

    @ObservationIgnored
    @LazyInjected(\SharedToolingContainer.logger) private var logger

    @ObservationIgnored
    @LazyInjected(\SharedUseCasesContainer.getSharedPreferences) private var getSharedPreferences

    @ObservationIgnored
    private var aliasDiscovery: AliasDiscovery {
        preferencesManager.sharedPreferences.unwrapped().aliasDiscovery
    }

    @ObservationIgnored
    private let itemIds: IDs

    @ObservationIgnored
    private var task: Task<Void, any Error>?

    init(itemIds: IDs) {
        self.itemIds = itemIds
    }

    func create() {
        guard canCreate else {
            return
        }

        let discovered = aliasDiscovery.contains(.copyContactAfterCreating)
        let enabled = getSharedPreferences().copyAfterCreatingContact
        if !enabled, !discovered {
            showCopyAfterCreatingAlert = true
            return
        }

        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            await doCreate()
        }
    }

    func dismissCopyAfterCreatingTip(optIn: Bool) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }

            // First dismiss the tip
            await performIgnoringError {
                var aliasDiscovery = aliasDiscovery
                if !aliasDiscovery.contains(.copyContactAfterCreating) {
                    aliasDiscovery.flip(.copyContactAfterCreating)
                    try await preferencesManager.updateSharedPreferences(\.aliasDiscovery,
                                                                         value: aliasDiscovery)
                }
            }

            // Then optionally opt-in
            await performIgnoringError {
                if optIn {
                    try await preferencesManager.updateSharedPreferences(\.copyAfterCreatingContact,
                                                                         value: true)
                }
            }

            await doCreate()
        }
    }
}

private extension CreateContactViewModel {
    func doCreate() async {
        defer { loading = false }
        do {
            loading = true
            let userId = try await userManager.getActiveUserId()
            let request = CreateAContactRequest(email: email, name: name.nilIfEmpty)
            createdContact = try await aliasRepository.createContact(userId: userId,
                                                                     shareId: itemIds.shareId,
                                                                     itemId: itemIds.itemId,
                                                                     request: request)
        } catch {
            logger.error(error)
            self.error = error
        }
    }

    func performIgnoringError(block: () async throws -> Void, function: String = #function) async {
        do {
            try await block()
        } catch {
            logger.error(error, function: function)
        }
    }
}
