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
import Factory
import Foundation
import Macro

@MainActor
final class CreateContactViewModel: ObservableObject, Sendable {
    @Published var email = ""
    @Published var name = ""
    @Published private(set) var canSave = false
    @Published var creationError: (any Error)?
    @Published private(set) var loading = false
    @Published private(set) var finishedSaving = false

    @LazyInjected(\SharedRepositoryContainer.aliasRepository) private var aliasRepository
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    @LazyInjected(\SharedToolingContainer.logger) private var logger

    private var cancellables = Set<AnyCancellable>()
    private let itemIds: IDs

    init(itemIds: IDs) {
        self.itemIds = itemIds
        setUp()
    }

    func saveContact() {
        guard !email.isEmpty else {
            return
        }
        Task { [weak self] in
            guard let self else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                let request = CreateAContactRequest(email: email, name: name.nilIfEmpty)
                try await aliasRepository.createContact(userId: userId,
                                                        shareId: itemIds.shareId,
                                                        itemId: itemIds.itemId,
                                                        request: request)
                finishedSaving = true
            } catch {
                creationError = error
            }
        }
    }
}

private extension CreateContactViewModel {
    func setUp() {
        $email
            .receive(on: DispatchQueue.main)
            .sink { [weak self] email in
                guard let self else {
                    return
                }
                canSave = email.isValidEmail()
            }
            .store(in: &cancellables)
    }
}
