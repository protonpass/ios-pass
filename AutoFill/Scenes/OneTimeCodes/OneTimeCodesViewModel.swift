//
// OneTimeCodesViewModel.swift
// Proton Pass - Created on 18/09/2024.
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

enum OneTimeCodesViewModelState {
    case loading
    case loaded
    case error(any Error)
}

@MainActor
final class OneTimeCodesViewModel: AutoFillViewModel<CredentialsFetchResult> {
    @Published private(set) var state = OneTimeCodesViewModelState.loading
    @Published var query = ""

    private let serviceIdentifiers: [ASCredentialServiceIdentifier]

    @LazyInjected(\AutoFillUseCaseContainer.fetchCredentials) private var fetchCredentials
    @LazyInjected(\AutoFillUseCaseContainer.autoFillOneTimeCode) private var autoFillOneTimeCode

    private let mapServiceIdentifierToURL = resolve(\AutoFillUseCaseContainer.mapServiceIdentifierToURL)
    let urls: [URL]

    var domain: String {
        urls.first?.host() ?? ""
    }

    private var searchableItems: [SearchableItem] {
        if let selectedUser {
            results.first { $0.userId == selectedUser.id }?.searchableItems ?? []
        } else {
            getAllObjects(\.searchableItems)
        }
    }

    var matchedItems: [ItemUiModel] {
        if let selectedUser {
            results
                .first { $0.userId == selectedUser.id }?
                .matchedItems
                .filter(\.hasTotpUri) ?? []
        } else {
            getAllObjects(\.matchedItems).filter(\.hasTotpUri)
        }
    }

    var notMatchedItems: [ItemUiModel] {
        if let selectedUser {
            results
                .first { $0.userId == selectedUser.id }?
                .notMatchedItems
                .filter(\.hasTotpUri) ?? []
        } else {
            getAllObjects(\.notMatchedItems).filter(\.hasTotpUri)
        }
    }

    init(users: [UserUiModel],
         serviceIdentifiers: [ASCredentialServiceIdentifier],
         context: ASCredentialProviderExtensionContext,
         userForNewItemSubject: UserForNewItemSubject) {
        self.serviceIdentifiers = serviceIdentifiers
        urls = serviceIdentifiers.compactMap(mapServiceIdentifierToURL.callAsFunction)
        super.init(context: context,
                   users: users,
                   userForNewItemSubject: userForNewItemSubject)
    }

    override func getVaults(userId: String) -> [Vault]? {
        results.first { $0.userId == userId }?.vaults
    }

    override func isErrorState() -> Bool {
        if case .error = state {
            true
        } else {
            false
        }
    }

    override func fetchAutoFillCredentials(userId: String) async throws -> CredentialsFetchResult {
        try await fetchCredentials(userId: userId, identifiers: serviceIdentifiers, params: nil)
    }

    override func changeToErrorState(_ error: any Error) {
        state = .error(error)
    }

    override func changeToLoadingState() {
        state = .loading
    }

    override func changeToLoadedState() {
        state = .loaded
    }
}

extension OneTimeCodesViewModel {
    func select(item: any ItemIdentifiable) {
        guard let context else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await autoFillOneTimeCode(item,
                                              serviceIdentifiers: serviceIdentifiers,
                                              context: context)
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }
}
