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
final class PasskeyCredentialsViewModel: AutoFillViewModel<CredentialsForPasskeyCreation> {
    @Published private(set) var state: PasskeyCredentialsViewModelState = .loading
    @Published private(set) var isCreatingPasskey = false
    @Published var isShowingAssociationConfirmation = false

    var selectedItem: (any TitledItemIdentifiable)? {
        didSet {
            if selectedItem != nil {
                isShowingAssociationConfirmation = true
            }
        }
    }

    @LazyInjected(\AutoFillUseCaseContainer.getItemsForPasskeyCreation) private var getItemsForPasskeyCreation
    @LazyInjected(\AutoFillUseCaseContainer.createAndAssociatePasskey) private var createAndAssociatePasskey

    private let request: PasskeyCredentialRequest

    private(set) var searchableItems: [SearchableItem] = []
    @Published private(set) var items: [ItemUiModel] = []

    init(users: [UserUiModel],
         request: PasskeyCredentialRequest,
         context: ASCredentialProviderExtensionContext?,
         userForNewItemSubject: UserForNewItemSubject) {
        self.request = request
        super.init(context: context,
                   users: users,
                   userForNewItemSubject: userForNewItemSubject)
    }

    override func getVaults(userId: String) -> [Share]? {
        results.first(where: { $0.userId == userId })?.vaults
    }

    override func generateItemCreationInfo(userId: String, vaults: [Share]) -> ItemCreationInfo {
        .init(userId: userId, vaults: vaults, data: .login(nil, request))
    }

    override func isErrorState() -> Bool {
        if case .error = state {
            true
        } else {
            false
        }
    }

    override func fetchAutoFillCredentials(userId: String) async throws -> CredentialsForPasskeyCreation {
        try await getItemsForPasskeyCreation(userId: userId, request)
    }

    override func changeToErrorState(_ error: any Error) {
        state = .error(error)
    }

    override func changeToLoadingState() {
        state = .loading
    }

    override nonisolated func fetchItems() async {
        await super.fetchItems()
        await filterItems()
    }
}

extension PasskeyCredentialsViewModel {
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
            handle(error)
        }
    }
}

private extension PasskeyCredentialsViewModel {
    nonisolated func filterItems() async {
        let searchableItems: [SearchableItem]
        let items: [ItemUiModel]

        if let selectedUser = await selectedUser,
           let result = await results.first(where: { $0.userId == selectedUser.id }) {
            searchableItems = result.searchableItems
            items = result.items
        } else {
            searchableItems = await getAllObjects(\.searchableItems)
            items = await getAllObjects(\.items)
        }

        await MainActor.run { [weak self] in
            guard let self else { return }
            self.searchableItems = searchableItems
            self.items = items
            state = .loaded
        }
    }
}
