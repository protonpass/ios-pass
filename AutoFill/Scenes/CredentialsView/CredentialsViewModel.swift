//
// CredentialsViewModel.swift
// Proton Pass - Created on 27/09/2022.
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

@preconcurrency import AuthenticationServices
import Client
import Core
import CryptoKit
import Entities
import Factory
import Macro
import Screens
import SwiftUI

enum CredentialsViewState: Equatable {
    /// Empty search query
    case idle
    case searching
    case searchResults([ItemSearchResult])
    case loading
    case error(any Error)

    static func == (lhs: CredentialsViewState, rhs: CredentialsViewState) -> Bool {
        switch (lhs, rhs) {
        case let (.error(lhsError), .error(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        case (.idle, .idle),
             (.loading, .loading),
             (.searching, .searching),
             (.searchResults, .searchResults):
            true
        default:
            false
        }
    }
}

protocol TitledItemIdentifiable: ItemIdentifiable {
    var itemTitle: String { get }
}

protocol CredentialItem: DateSortable, AlphabeticalSortable, TitledItemIdentifiable, Identifiable {}

extension ItemUiModel: CredentialItem {
    var itemTitle: String { title }
}

extension ItemSearchResult: CredentialItem {
    var itemTitle: String { highlightableTitle.fullText }
}

@MainActor
final class CredentialsViewModel: AutoFillViewModel<CredentialsFetchResult> {
    @Published private(set) var state = CredentialsViewState.loading
    @Published var query = ""
    @Published var notMatchedItemInformation: UnmatchedItemAlertInformation?
    @Published var selectPasskeySheetInformation: SelectPasskeySheetInformation?

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    private var lastTask: Task<Void, Never>?

    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\AutoFillUseCaseContainer.fetchCredentials) private var fetchCredentials
    @LazyInjected(\AutoFillUseCaseContainer.autoFillPassword) private var autoFillPassword
    @LazyInjected(\AutoFillUseCaseContainer
        .associateUrlAndAutoFillPassword) private var associateUrlAndAutoFillPassword
    @LazyInjected(\AutoFillUseCaseContainer.autoFillPasskey) private var autoFillPasskey

    private let serviceIdentifiers: [ASCredentialServiceIdentifier]
    private let passkeyRequestParams: (any PasskeyRequestParametersProtocol)?
    private let urls: [URL]
    private let mapServiceIdentifierToURL = resolve(\AutoFillUseCaseContainer.mapServiceIdentifierToURL)
    private let canEditItem = resolve(\SharedUseCasesContainer.canEditItem)

    var domain: String {
        if let passkeyRequestParams {
            passkeyRequestParams.relyingPartyIdentifier
        } else {
            urls.first?.host() ?? ""
        }
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
            results.first { $0.userId == selectedUser.id }?.matchedItems ?? []
        } else {
            getAllObjects(\.matchedItems)
        }
    }

    var notMatchedItems: [ItemUiModel] {
        if let selectedUser {
            results.first { $0.userId == selectedUser.id }?.notMatchedItems ?? []
        } else {
            getAllObjects(\.notMatchedItems)
        }
    }

    init(users: [UserUiModel],
         serviceIdentifiers: [ASCredentialServiceIdentifier],
         passkeyRequestParams: (any PasskeyRequestParametersProtocol)?,
         context: ASCredentialProviderExtensionContext,
         userForNewItemSubject: UserForNewItemSubject) {
        self.serviceIdentifiers = serviceIdentifiers
        self.passkeyRequestParams = passkeyRequestParams
        urls = serviceIdentifiers.compactMap(mapServiceIdentifierToURL.callAsFunction)
        super.init(context: context,
                   users: users,
                   userForNewItemSubject: userForNewItemSubject)
        setup()
    }

    override func getVaults(userId: String) -> [Vault]? {
        results.first { $0.userId == userId }?.vaults
    }

    override func generateLoginCreationInfo(userId: String, vaults: [Vault]) -> LoginCreationInfo {
        .init(userId: userId, vaults: vaults, url: urls.first, request: nil)
    }

    override func isErrorState() -> Bool {
        if case .error = state {
            true
        } else {
            false
        }
    }

    override func fetchAutoFillCredentials(userId: String) async throws -> CredentialsFetchResult {
        try await fetchCredentials(userId: userId,
                                   identifiers: serviceIdentifiers,
                                   params: passkeyRequestParams)
    }

    override func changeToErrorState(_ error: any Error) {
        state = .error(error)
    }

    override func changeToLoadingState() {
        state = .loading
    }

    override func changeToLoadedState() {
        state = .idle
    }
}

// MARK: - Public actions

extension CredentialsViewModel {
    func presentSortTypeList() {
        delegate?.autoFillViewModelWantsToPresentSortTypeList(selectedSortType: selectedSortType,
                                                              delegate: self)
    }

    func associateAndAutofill(item: any ItemIdentifiable) {
        Task { [weak self] in
            guard let self, let context else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            router.display(element: .globalLoading(shouldShow: true))
            do {
                logger.trace("Associate and autofilling \(item.debugDescription)")
                try await associateUrlAndAutoFillPassword(item: item,
                                                          urls: urls,
                                                          serviceIdentifiers: serviceIdentifiers,
                                                          context: context)
                logger.info("Associate and autofill successfully \(item.debugDescription)")
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }

    func select(item: any ItemIdentifiable) {
        assert(!results.isEmpty, "Credentials are not fetched")

        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                if let passkeyRequestParams {
                    try await handlePasskeySelection(for: item,
                                                     params: passkeyRequestParams)
                } else {
                    try await handlePasswordSelection(for: item)
                }
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }
}

private extension CredentialsViewModel {
    func handlePasswordSelection(for item: any ItemIdentifiable) async throws {
        guard let context else { return }
        // Check if given URL is valid and user has edit right before proposing "associate & autofill"
        if notMatchedItemInformation == nil,
           canEditItem(vaults: results.flatMap(\.vaults), item: item),
           let schemeAndHost = urls.first?.schemeAndHost,
           !schemeAndHost.isEmpty,
           let notMatchedItem = notMatchedItems
           .first(where: { $0.itemId == item.itemId && $0.shareId == item.shareId }) {
            notMatchedItemInformation = UnmatchedItemAlertInformation(item: notMatchedItem,
                                                                      url: schemeAndHost)
            return
        }

        // Given URL is not valid or item is matched, in either case just autofill normally
        try await autoFillPassword(item, serviceIdentifiers: serviceIdentifiers, context: context)
    }

    func handlePasskeySelection(for item: any ItemIdentifiable,
                                params: any PasskeyRequestParametersProtocol) async throws {
        guard let context else { return }
        guard let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                        itemId: item.itemId),
            let loginData = itemContent.loginItem else {
            throw PassError.itemNotFound(item)
        }

        guard !loginData.passkeys.isEmpty else {
            // Fallback to password autofill when no passkeys
            try await handlePasswordSelection(for: item)
            return
        }

        if loginData.passkeys.count == 1,
           let passkey = loginData.passkeys.first {
            // Item has only 1 passkey => autofill right away
            try await autoFillPasskey(passkey,
                                      itemContent: itemContent,
                                      identifiers: serviceIdentifiers,
                                      params: params,
                                      context: context)
        } else {
            // Item has more than 1 passkey => ask user to choose
            selectPasskeySheetInformation = .init(itemContent: itemContent,
                                                  identifiers: serviceIdentifiers,
                                                  params: params,
                                                  passkeys: loginData.passkeys)
        }
    }
}

private extension CredentialsViewModel {
    func doSearch(term: String) {
        guard state != .searching else { return }
        guard !term.isEmpty else {
            state = .idle
            return
        }

        lastTask?.cancel()
        lastTask = Task { [weak self] in
            guard let self else {
                return
            }
            let hashedTerm = term.sha256
            logger.trace("Searching for term \(hashedTerm)")
            state = .searching
            let searchResults = searchableItems.result(for: term)
            if Task.isCancelled {
                return
            }
            state = .searchResults(searchResults)
            if searchResults.isEmpty {
                logger.trace("No results for term \(hashedTerm)")
            } else {
                logger.trace("Found results for term \(hashedTerm)")
            }
        }
    }
}

// MARK: Setup & utils functions

private extension CredentialsViewModel {
    func setup() {
        $query
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] term in
                guard let self else { return }
                doSearch(term: term)
            }
            .store(in: &cancellables)
    }
}

// MARK: - SortTypeListViewModelDelegate

extension CredentialsViewModel: SortTypeListViewModelDelegate {
    func sortTypeListViewDidSelect(_ sortType: SortType) {
        selectedSortType = sortType
    }
}
