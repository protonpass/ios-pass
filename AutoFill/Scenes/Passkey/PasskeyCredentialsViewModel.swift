//
// PasskeyCredentialsViewModel.swift
// Proton Pass - Created on 27/02/2024.
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

@preconcurrency import AuthenticationServices
import Client
import Entities
import Factory
import Foundation

enum PasskeyCredentialsViewModelState {
    case loading
    case loaded
    case error(any Error)
}

@MainActor
final class PasskeyCredentialsViewModel: ObservableObject {
    @Published private(set) var results: [CredentialsForPasskeyCreation] = []
    @Published private(set) var state: PasskeyCredentialsViewModelState = .loading
    @Published private(set) var isCreatingPasskey = false
    @Published var isShowingAssociationConfirmation = false
    @Published var selectedUser: PassUser?

    let users: [PassUser]

    var selectedItem: (any TitledItemIdentifiable)? {
        didSet {
            if selectedItem != nil {
                isShowingAssociationConfirmation = true
            }
        }
    }

    private let logger = resolve(\SharedToolingContainer.logger)

    @LazyInjected(\SharedServiceContainer.eventSynchronizer) private(set) var eventSynchronizer
    @LazyInjected(\AutoFillUseCaseContainer.getItemsForPasskeyCreation) private var getItemsForPasskeyCreation
    @LazyInjected(\AutoFillUseCaseContainer.createAndAssociatePasskey) private var createAndAssociatePasskey

    private let request: PasskeyCredentialRequest
    private weak var context: ASCredentialProviderExtensionContext?

    var searchableItems: [SearchableItem] {
        if let selectedUser {
            results.first(where: { $0.userId == selectedUser.id })?.searchableItems ?? []
        } else {
            []
        }
    }

    init(users: [PassUser],
         request: PasskeyCredentialRequest,
         context: ASCredentialProviderExtensionContext?) {
        self.users = users
        self.request = request
        self.context = context
    }
}

extension PasskeyCredentialsViewModel {
    func sync(ignoreError: Bool) async {
        do {
            var shouldRefreshItems = false
            for user in users {
                let hasNewEvents = try await eventSynchronizer.sync(userId: user.id)
                shouldRefreshItems = shouldRefreshItems || hasNewEvents
            }

            if shouldRefreshItems {
                await loadCredentials()
            }
        } catch {
            logger.error(error)
            if !ignoreError {
                state = .error(error)
            }
        }
    }

    func loadCredentials() async {
        do {
            logger.trace("Loading credentials")
            if case .error = state {
                state = .loading
            }
            /*
             let userId = try await userManager.getActiveUserId()
             let result = try await getItemsForPasskeyCreation(userId: userId, request)
             state = .loaded(result.0, result.1)
             logger.trace("Loaded \(result.0.count) credentials")
              */
        } catch {
            state = .error(error)
        }
    }

    func createAndAssociatePasskey() async {
        guard let context else { return }
        guard let selectedItem else {
            assertionFailure("Item shall not be nil")
            return
        }

        defer { isCreatingPasskey = false }

        do {
            isCreatingPasskey = true
            try await createAndAssociatePasskey(item: selectedItem,
                                                request: request,
                                                context: context)
        } catch {
            state = .error(error)
        }
    }
}
