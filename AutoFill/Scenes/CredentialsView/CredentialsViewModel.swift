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

@MainActor
final class CredentialsViewModel: AutoFillViewModel<CredentialsFetchResult> {
    @Published private(set) var state = CredentialsViewState.loading
    @Published var query = ""
    @Published var notMatchedItemInformation: UnmatchedItemAlertInformation?
    @Published var selectPasskeySheetInformation: SelectPasskeySheetInformation?

    private var searchTask: Task<Void, Never>?
    private var sortTask: Task<Void, Never>?
    private var filterAndSortTask: Task<Void, Never>?

    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\AutoFillUseCaseContainer.fetchCredentials) private var fetchCredentials
    @LazyInjected(\AutoFillUseCaseContainer.autoFillCredentials) private var autoFillCredentials
    @LazyInjected(\AutoFillUseCaseContainer.autoFillPasskey) private var autoFillPasskey

    private let serviceIdentifiers: [ASCredentialServiceIdentifier]
    private let passkeyRequestParams: (any PasskeyRequestParametersProtocol)?
    private let urls: [URL]
    private let mapServiceIdentifierToURL = resolve(\AutoFillUseCaseContainer.mapServiceIdentifierToURL)
    let mode: CredentialsMode

    var domain: String {
        if let passkeyRequestParams {
            passkeyRequestParams.relyingPartyIdentifier
        } else {
            urls.first?.host() ?? ""
        }
    }

    private var searchableItems = [SearchableItem]()
    private var notMatchedItems = [ItemUiModel]()

    @Published private(set) var matchedItems = [ItemUiModel]()
    @Published private(set) var notMatchedItemSections: FetchableObject<[SectionedItemUiModel]> = .fetching

    init(mode: CredentialsMode,
         users: [UserUiModel],
         serviceIdentifiers: [ASCredentialServiceIdentifier],
         passkeyRequestParams: (any PasskeyRequestParametersProtocol)?,
         context: ASCredentialProviderExtensionContext,
         userForNewItemSubject: UserForNewItemSubject) {
        self.mode = mode
        self.serviceIdentifiers = serviceIdentifiers
        self.passkeyRequestParams = passkeyRequestParams
        urls = serviceIdentifiers.compactMap(mapServiceIdentifierToURL.callAsFunction)
        super.init(context: context,
                   users: users,
                   userForNewItemSubject: userForNewItemSubject)
    }

    override func setUp() {
        super.setUp()
        $query
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .dropFirst()
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] term in
                guard let self else { return }
                doSearch(term: term)
            }
            .store(in: &cancellables)

        $selectedUser
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                filterAndSortTask?.cancel()
                filterAndSortTask = Task { [weak self] in
                    guard let self else { return }
                    await filterAndSortItemsAsync()
                }
            }
            .store(in: &cancellables)

        sortTypeUpdated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                sortTask?.cancel()
                sortTask = Task { [weak self] in
                    guard let self else { return }
                    await sortNotMatchedItemsAsync()
                }
            }
            .store(in: &cancellables)
    }

    override nonisolated func fetchItems() async {
        await super.fetchItems()
        await filterAndSortItemsAsync()
    }

    override func getVaults(userId: String) -> [Vault]? {
        results.first { $0.userId == userId }?.vaults
    }

    override func generateItemCreationInfo(userId: String, vaults: [Vault]) -> ItemCreationInfo {
        .init(userId: userId, vaults: vaults, data: .login(urls.first, nil))
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

    nonisolated func filterAndSortItemsAsync() async {
        do {
            try await filterItemsAsync()
            await sortNotMatchedItemsAsync()
        } catch {
            await handle(error)
        }
    }
}

// MARK: - Public actions

extension CredentialsViewModel {
    func associateAndAutofill(item: any ItemIdentifiable) {
        Task { [weak self] in
            guard let self, let context else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            router.display(element: .globalLoading(shouldShow: true))
            do {
                logger.trace("Associate and autofilling \(item.debugDescription)")
                try await associateUrlAndAutoFill(item: item,
                                                  mode: mode,
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

    func select(item: any ItemIdentifiable,
                skipUrlAssociationCheck: Bool = false) {
        assert(!results.isEmpty, "Credentials are not fetched")

        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                if let passkeyRequestParams {
                    try await handlePasskeySelection(for: item,
                                                     params: passkeyRequestParams,
                                                     skipUrlAssociationCheck: skipUrlAssociationCheck)
                } else {
                    try await handlePasswordSelection(for: item,
                                                      skipUrlAssociationCheck: skipUrlAssociationCheck)
                }
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }
}

private extension CredentialsViewModel {
    func handlePasswordSelection(for item: any ItemIdentifiable,
                                 skipUrlAssociationCheck: Bool) async throws {
        guard let context else { return }
        // Check if given URL is valid and user has edit right before proposing "associate & autofill"
        if !skipUrlAssociationCheck,
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
        try await autoFillCredentials(item,
                                      mode: mode,
                                      serviceIdentifiers: serviceIdentifiers,
                                      context: context)
    }

    func handlePasskeySelection(for item: any ItemIdentifiable,
                                params: any PasskeyRequestParametersProtocol,
                                skipUrlAssociationCheck: Bool) async throws {
        guard let context else { return }
        guard let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                        itemId: item.itemId),
            let loginData = itemContent.loginItem else {
            throw PassError.itemNotFound(item)
        }

        guard !loginData.passkeys.isEmpty else {
            // Fallback to password autofill when no passkeys
            try await handlePasswordSelection(for: item, skipUrlAssociationCheck: skipUrlAssociationCheck)
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
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await searchAsync(term: term)
            } catch {
                handle(error)
            }
        }
    }

    nonisolated func searchAsync(term: String) async throws {
        await MainActor.run { [weak self] in
            guard let self, state != .searching else { return }
        }
        guard !term.isEmpty else {
            await MainActor.run { [weak self] in
                guard let self else { return }
                state = .idle
            }
            return
        }

        let hashedTerm = term.sha256
        await MainActor.run { [weak self] in
            guard let self else { return }
            logger.trace("Searching for term \(hashedTerm)")
            state = .searching
        }

        let searchResults = try await searchableItems.result(for: term)
        await MainActor.run { [weak self] in
            guard let self else { return }
            state = .searchResults(searchResults)
            if searchResults.isEmpty {
                logger.trace("No results for term \(hashedTerm)")
            } else {
                logger.trace("Found results for term \(hashedTerm)")
            }
        }
    }

    nonisolated func filterItemsAsync() async throws {
        await MainActor.run { [weak self] in
            guard let self else { return }
            state = .loading
        }

        var searchableItems = [SearchableItem]()
        var matchedItems = [ItemUiModel]()
        var notMatchedItems = [ItemUiModel]()

        if let selectedUser = await selectedUser,
           let result = await results.first(where: { $0.userId == selectedUser.id }) {
            searchableItems = result.searchableItems
            matchedItems = result.matchedItems
            notMatchedItems = result.notMatchedItems
        } else {
            // Avoid async let here to reduce memory footprint
            searchableItems = await getAllObjects(\.searchableItems)
            matchedItems = await getAllObjects(\.matchedItems)
            notMatchedItems = await getAllObjects(\.notMatchedItems)
        }

        if case .oneTimeCodes = mode {
            searchableItems = searchableItems.filter(\.hasTotpUri)
            matchedItems = matchedItems.filter(\.hasTotpUri)
            notMatchedItems = notMatchedItems.filter(\.hasTotpUri)
        }

        await MainActor.run { [weak self] in
            guard let self else { return }
            self.searchableItems = searchableItems
            self.matchedItems = matchedItems
            self.notMatchedItems = notMatchedItems
            state = .idle
        }
    }

    nonisolated func sortNotMatchedItemsAsync() async {
        await MainActor.run { [weak self] in
            guard let self else { return }
            notMatchedItemSections = .fetching
        }

        let items = await notMatchedItems
        let sortType = await selectedSortType
        let sectionedItems: [SectionedItemUiModel]
        do {
            switch sortType {
            case .mostRecent:
                let sortedResult = try items.mostRecentSortResult()
                sectionedItems = sortedResult.buckets.map { bucket in
                    SectionedItemUiModel(id: bucket.id,
                                         sectionTitle: bucket.type.title,
                                         items: bucket.items)
                }

            case .alphabeticalAsc, .alphabeticalDesc:
                let sortedResult = try items.alphabeticalSortResult(direction: sortType.sortDirection)
                sectionedItems = sortedResult.buckets.map { bucket in
                    SectionedItemUiModel(id: bucket.letter.character,
                                         sectionTitle: bucket.letter.character,
                                         items: bucket.items)
                }

            case .newestToOldest, .oldestToNewest:
                let sortedResult = try items.monthYearSortResult(direction: sortType.sortDirection)
                sectionedItems = sortedResult.buckets.map { bucket in
                    SectionedItemUiModel(id: bucket.monthYear.relativeString,
                                         sectionTitle: bucket.monthYear.relativeString,
                                         items: bucket.items)
                }
            }

            await MainActor.run { [weak self] in
                guard let self else { return }
                notMatchedItemSections = .fetched(sectionedItems)
            }
        } catch {
            if error is CancellationError { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                notMatchedItemSections = .error(error)
            }
        }
    }
}
