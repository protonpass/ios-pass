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
import Combine
import Core
import CryptoKit
import Entities
import Factory
import Macro
import Screens
import SwiftUI

@MainActor
protocol CredentialsViewModelDelegate: AnyObject {
    func credentialsViewModelWantsToCancel()
    func credentialsViewModelWantsToLogOut()
    func credentialsViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                        delegate: any SortTypeListViewModelDelegate)
    func credentialsViewModelWantsToCreateNewItem(_ mode: AutoFillCreationMode)
}

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
final class CredentialsViewModel: ObservableObject {
    @Published private(set) var state = CredentialsViewState.loading
    @Published private(set) var results: [CredentialsFetchResult] = []
    @Published private(set) var users: [PassUser]
    @Published var selectedUser: PassUser?
    @Published var query = ""
    @Published var notMatchedItemInformation: UnmatchedItemAlertInformation?
    @Published var selectPasskeySheetInformation: SelectPasskeySheetInformation?
    @Published var isShowingConfirmationAlert = false

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    var result: CredentialsFetchResult? {
        results.first { $0.userId == selectedUser?.id }
    }

    private var lastTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\SharedRepositoryContainer.shareRepository) private var shareRepository
    @LazyInjected(\SharedRepositoryContainer.accessRepository) private var accessRepository
    @LazyInjected(\SharedServiceContainer.eventSynchronizer) private(set) var eventSynchronizer
    @LazyInjected(\AutoFillUseCaseContainer.fetchCredentials) private var fetchCredentials
    @LazyInjected(\AutoFillUseCaseContainer.autoFillPassword) private var autoFillPassword
    @LazyInjected(\AutoFillUseCaseContainer
        .associateUrlAndAutoFillPassword) private var associateUrlAndAutoFillPassword
    @LazyInjected(\AutoFillUseCaseContainer.autoFillPasskey) private var autoFillPasskey

    private let serviceIdentifiers: [ASCredentialServiceIdentifier]
    private let passkeyRequestParams: (any PasskeyRequestParametersProtocol)?
    private let urls: [URL]
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let mapServiceIdentifierToURL = resolve(\AutoFillUseCaseContainer.mapServiceIdentifierToURL)
    private let canEditItem = resolve(\SharedUseCasesContainer.canEditItem)

    weak var delegate: (any CredentialsViewModelDelegate)?
    private(set) weak var context: ASCredentialProviderExtensionContext?

    var domain: String {
        if let passkeyRequestParams {
            passkeyRequestParams.relyingPartyIdentifier
        } else {
            urls.first?.host() ?? ""
        }
    }

    var planType: Plan.PlanType? {
        selectedUser?.plan.planType
    }

    private var searchableItems: [SearchableItem] {
        if let selectedUser {
            return results.first { $0.userId == selectedUser.id }?.searchableItems ?? []
        } else {
            do {
                return try results.mergeAndDeduplicate(by: \.searchableItems,
                                                       vaultId: { try getVaultId(from: $0) })
            } catch {
                router.display(element: .displayErrorBanner(error))
                return []
            }
        }
    }

    var matchedItems: [ItemUiModel] {
        if let selectedUser {
            return results.first { $0.userId == selectedUser.id }?.matchedItems ?? []
        } else {
            do {
                return try results.mergeAndDeduplicate(by: \.matchedItems,
                                                       vaultId: { try getVaultId(from: $0) })
            } catch {
                router.display(element: .displayErrorBanner(error))
                return []
            }
        }
    }

    var notMatchedItems: [ItemUiModel] {
        if let selectedUser {
            return results.first { $0.userId == selectedUser.id }?.notMatchedItems ?? []
        } else {
            do {
                return try results.mergeAndDeduplicate(by: \.notMatchedItems,
                                                       vaultId: { try getVaultId(from: $0) })
            } catch {
                router.display(element: .displayErrorBanner(error))
                return []
            }
        }
    }

    private var shareIdToVaultIdDict = [String: String]() // ShareID -> VaultID
    private var shareIdToUserIdDict = [String: String]() // ShareID -> UserID

    init(users: [PassUser],
         serviceIdentifiers: [ASCredentialServiceIdentifier],
         passkeyRequestParams: (any PasskeyRequestParametersProtocol)?,
         context: ASCredentialProviderExtensionContext) {
        self.users = users
        if users.count == 1 {
            selectedUser = users.first
        }
        self.serviceIdentifiers = serviceIdentifiers
        self.passkeyRequestParams = passkeyRequestParams
        self.context = context
        urls = serviceIdentifiers.compactMap(mapServiceIdentifierToURL.callAsFunction)
        setup()
    }
}

// MARK: - Public actions

extension CredentialsViewModel {
    func cancel() {
        delegate?.credentialsViewModelWantsToCancel()
    }

    func sync() async {
        do {
            var shouldRefreshItems = false
            for user in users {
                let hasNewEvents = try await eventSynchronizer.sync(userId: user.id)
                shouldRefreshItems = shouldRefreshItems || hasNewEvents
            }

            if shouldRefreshItems {
                await fetchItems()
            }
        } catch {
            state = .error(error)
        }
    }

    func fetchItems() async {
        do {
            logger.trace("Loading log in items")
            if case .error = state {
                state = .loading
            }

            var results = [CredentialsFetchResult]()
            for user in users {
                let result = try await fetchCredentials(userId: user.id,
                                                        identifiers: serviceIdentifiers,
                                                        params: passkeyRequestParams)
                results.append(result)
            }

            self.results = results

            state = .idle
            logger.info("Loaded log in items")
        } catch {
            logger.error(error)
            state = .error(error)
        }
    }

    func fetchItemsSync() {
        Task { [weak self] in
            guard let self else { return }
            await fetchItems()
        }
    }

    func presentSortTypeList() {
        delegate?.credentialsViewModelWantsToPresentSortTypeList(selectedSortType: selectedSortType,
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

    func handleAuthenticationSuccess() {
        logger.info("Local authentication succesful")
    }

    func handleAuthenticationFailure() {
        logger.error("Failed to locally authenticate. Logging out.")
        delegate?.credentialsViewModelWantsToLogOut()
    }

    func createNewItem(_ type: ItemType) {
        switch type {
        case .login:
            delegate?.credentialsViewModelWantsToCreateNewItem(.login(urls.first, nil))
        case .alias:
            delegate?.credentialsViewModelWantsToCreateNewItem(.alias)
        default:
            assertionFailure("Item type \(type.description) not supported")
        }
    }

    func getUser(for item: any ItemIdentifiable) -> PassUser? {
        if let userId = shareIdToUserIdDict[item.shareId] {
            return users.first { $0.id == userId }
        }
        if let result = results.first(where: { $0.vaults.contains { $0.shareId == item.shareId } }),
           let user = users.first(where: { $0.id == result.userId }) {
            shareIdToUserIdDict[item.shareId] = user.id
            return user
        }
        return nil
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
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

    func getVaultId(from shareId: String) throws -> String {
        if let vaultId = shareIdToVaultIdDict[shareId] {
            return vaultId
        }
        if let vault = results.flatMap(\.vaults).first(where: { $0.shareId == shareId }) {
            shareIdToVaultIdDict[shareId] = vault.id
            return vault.id
        }
        throw PassError.vault(.vaultNotFound(shareId: shareId))
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

        $notMatchedItemInformation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                isShowingConfirmationAlert = true
            }
            .store(in: &cancellables)

        $isShowingConfirmationAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] showing in
                guard let self, !showing else { return }
                notMatchedItemInformation = nil
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

private extension [CredentialsFetchResult] {
    func mergeAndDeduplicate<T: ItemIdentifiable & Hashable>
    (by keyPath: KeyPath<CredentialsFetchResult, [T]>,
     vaultId: (_ shareId: String) throws -> String) rethrows -> [T] {
        try flatMap { $0[keyPath: keyPath] }
            .deduplicate { item in
                let vaultId = try vaultId(item.shareId)
                return vaultId + item.itemId
            }
            .compactMap { $0 }
    }
}
