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
import SwiftUI

@MainActor
protocol CredentialsViewModelDelegate: AnyObject {
    func credentialsViewModelWantsToCancel()
    func credentialsViewModelWantsToLogOut()
    func credentialsViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                        delegate: SortTypeListViewModelDelegate)
    func credentialsViewModelWantsToCreateLoginItem(shareId: String, url: URL?)
    func credentialsViewModelDidSelect(credential: ASPasswordCredential,
                                       itemContent: ItemContent,
                                       serviceIdentifiers: [ASCredentialServiceIdentifier])
}

enum CredentialsViewState: Equatable {
    /// Empty search query
    case idle
    case searching
    case searchResults([ItemSearchResult])
    case loading
    case error(Error)

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
    @Published private(set) var results: CredentialsFetchResult?
    @Published private(set) var planType: Plan.PlanType?
    @Published var query = ""
    @Published var notMatchedItemInformation: UnmatchedItemAlertInformation?
    @Published var isShowingConfirmationAlert = false

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)

    var selectedSortType = SortType.mostRecent

    private var lastTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    @LazyInjected(\SharedRepositoryContainer.shareRepository) private var shareRepository
    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\SharedDataContainer.symmetricKeyProvider) private var symmetricKeyProvider
    @LazyInjected(\SharedRepositoryContainer.accessRepository) private var accessRepository
    @LazyInjected(\SharedServiceContainer.eventSynchronizer) private(set) var eventSynchronizer

    private let serviceIdentifiers: [ASCredentialServiceIdentifier]
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let mapServiceIdentifierToURL = resolve(\AutoFillUseCaseContainer.mapServiceIdentifierToURL)
    private let canEditItem = resolve(\SharedUseCasesContainer.canEditItem)

    let urls: [URL]
    private var vaults = [Vault]()

    weak var delegate: CredentialsViewModelDelegate?

    init(serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        self.serviceIdentifiers = serviceIdentifiers
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
            let hasNewEvents = try await eventSynchronizer.sync()
            if hasNewEvents {
                fetchItems()
            }
        } catch {
            state = .error(error)
        }
    }

    func fetchItems() {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                logger.trace("Loading log in items")
                if case .error = state {
                    state = .loading
                }
                let plan = try await accessRepository.getPlan()
                planType = plan.planType

                results = try await fetchCredentials(plan: plan)
                state = .idle
                logger.info("Loaded log in items")
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }

    func presentSortTypeList() {
        delegate?.credentialsViewModelWantsToPresentSortTypeList(selectedSortType: selectedSortType,
                                                                 delegate: self)
    }

    func associateAndAutofill(item: any ItemIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            router.display(element: .globalLoading(shouldShow: true))
            do {
                let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
                logger.trace("Associate and autofilling \(item.debugDescription)")
                let encryptedItem = try await getItemTask(item: item).value
                let oldContent = try encryptedItem.getItemContent(symmetricKey: symmetricKey)
                guard case let .login(oldData) = oldContent.contentData else {
                    throw PassError.credentialProvider(.notLogInItem)
                }
                guard let newUrl = self.urls.first?.schemeAndHost, !newUrl.isEmpty else {
                    throw PassError.credentialProvider(.invalidURL(urls.first))
                }
                let newLoginData = ItemContentData.login(.init(username: oldData.username,
                                                               password: oldData.password,
                                                               totpUri: oldData.totpUri,
                                                               urls: oldData.urls + [newUrl],
                                                               allowedAndroidApps: oldData.allowedAndroidApps))
                let newContent = ItemContentProtobuf(name: oldContent.name,
                                                     note: oldContent.note,
                                                     itemUuid: oldContent.itemUuid,
                                                     data: newLoginData,
                                                     customFields: oldContent.customFields)
                try await itemRepository.updateItem(oldItem: encryptedItem.item,
                                                    newItemContent: newContent,
                                                    shareId: encryptedItem.shareId)
                autoFill(item: item)
                logger.info("Associate and autofill successfully \(item.debugDescription)")
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }

    func select(item: any ItemIdentifiable) {
        assert(results != nil, "Credentials are not fetched")
        guard let results else { return }

        Task { [weak self] in
            guard let self else {
                return
            }
            // Check if given URL is valid before proposing "associate & autofill"
            if canEditItem(vaults: vaults, item: item),
               notMatchedItemInformation == nil,
               let schemeAndHost = urls.first?.schemeAndHost,
               !schemeAndHost.isEmpty,
               let notMatchedItem = results.notMatchedItems
               .first(where: { $0.itemId == item.itemId && $0.shareId == item.shareId }) {
                notMatchedItemInformation = UnmatchedItemAlertInformation(item: notMatchedItem,
                                                                          url: schemeAndHost)
                return
            }

            // Given URL is not valid or item is matched, in either case just autofill normally
            autoFill(item: item)
        }
    }

    func autoFill(item: any ItemIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                logger.trace("Selecting \(item.debugDescription)")
                let (credential, itemContent) = try await getCredentialTask(for: item).value
                delegate?.credentialsViewModelDidSelect(credential: credential,
                                                        itemContent: itemContent,
                                                        serviceIdentifiers: serviceIdentifiers)
                logger.info("Selected \(item.debugDescription)")
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

    func createLoginItem() {
        guard case .idle = state else { return }
        Task { @MainActor [weak self] in
            guard let self,
                  let mainVault = vaults.oldestOwned else { return }
            self.delegate?.credentialsViewModelWantsToCreateLoginItem(shareId: mainVault.shareId,
                                                                      url: self.urls.first)
        }
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
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
        lastTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            let hashedTerm = term.sha256
            logger.trace("Searching for term \(hashedTerm)")
            state = .searching
            let searchResults = results?.searchableItems.result(for: term) ?? []
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
        fetchItems()

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

// MARK: - Private supporting tasks

private extension CredentialsViewModel {
    func getItemTask(item: any ItemIdentifiable) -> Task<SymmetricallyEncryptedItem, Error> {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else {
                throw PassError.CredentialProviderFailureReason.generic
            }
            guard let encryptedItem =
                try await itemRepository.getItem(shareId: item.shareId,
                                                 itemId: item.itemId) else {
                throw PassError.itemNotFound(item)
            }
            return encryptedItem
        }
    }

    func fetchCredentials(plan: Plan) async throws
        -> CredentialsFetchResult {
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()

        vaults = try await shareRepository.getVaults()
        let encryptedItems = try await itemRepository.getActiveLogInItems()
        logger.debug("Mapping \(encryptedItems.count) encrypted items")

        let domainParser = try DomainParser()
        var searchableItems = [SearchableItem]()
        var matchedEncryptedItems = [ScoredSymmetricallyEncryptedItem]()
        var notMatchedEncryptedItems = [SymmetricallyEncryptedItem]()
        for encryptedItem in encryptedItems {
            let decryptedItemContent = try encryptedItem.getItemContent(symmetricKey: symmetricKey)

            let vault = vaults.first { $0.shareId == encryptedItem.shareId }
            assert(vault != nil, "Must have at least 1 vault")
            guard await shouldTakeIntoAccount(vaults: vaults,
                                              vault: vault,
                                              withPlan: plan) else {
                continue
            }

            if case let .login(data) = decryptedItemContent.contentData {
                try searchableItems.append(SearchableItem(from: encryptedItem,
                                                          symmetricKey: symmetricKey,
                                                          allVaults: vaults))

                let itemUrls = data.urls.compactMap { URL(string: $0) }
                var matchResults = [URLUtils.Matcher.MatchResult]()
                for itemUrl in itemUrls {
                    for url in urls {
                        let result = URLUtils.Matcher.compare(itemUrl, url, domainParser: domainParser)
                        if case .matched = result {
                            matchResults.append(result)
                        }
                    }
                }

                if matchResults.isEmpty {
                    notMatchedEncryptedItems.append(encryptedItem)
                } else {
                    let totalScore = matchResults.reduce(into: 0) { partialResult, next in
                        partialResult += next.score
                    }
                    matchedEncryptedItems.append(.init(item: encryptedItem,
                                                       matchScore: totalScore))
                }
            }
        }

        let matchedItems = try await matchedEncryptedItems.sorted()
            .parallelMap { try $0.item.toItemUiModel(symmetricKey) }
        let notMatchedItems = try await notMatchedEncryptedItems.sorted()
            .parallelMap { try $0.toItemUiModel(symmetricKey) }

        logger.debug("Mapped \(encryptedItems.count) encrypted items.")
        logger.debug("\(vaults.count) vaults, \(searchableItems.count) searchable items")
        logger.debug("\(matchedItems.count) matched items, \(notMatchedItems.count) not matched items")
        return CredentialsFetchResult(vaults: vaults,
                                      searchableItems: searchableItems,
                                      matchedItems: matchedItems,
                                      notMatchedItems: notMatchedItems)
    }

    func getCredentialTask(for item: any ItemIdentifiable) -> Task<(ASPasswordCredential, ItemContent), Error> {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else {
                throw PassError.CredentialProviderFailureReason.generic
            }
            guard let itemContent =
                try await itemRepository.getItemContent(shareId: item.shareId,
                                                        itemId: item.itemId) else {
                throw PassError.itemNotFound(item)
            }

            switch itemContent.contentData {
            case let .login(data):
                let credential = ASPasswordCredential(user: data.username, password: data.password)
                return (credential, itemContent)
            default:
                throw PassError.credentialProvider(.notLogInItem)
            }
        }
    }

    /// When in free plan, only take 2 oldest vaults into account (suggestions & search)
    /// Otherwise take everything into account
    func shouldTakeIntoAccount(vaults: [Vault], vault: Vault?, withPlan plan: Plan) async -> Bool {
        guard let vault else { return true }
        switch plan.planType {
        case .free:
            let oldestVaults = vaults.twoOldestVaults
            return oldestVaults.isOneOf(shareId: vault.shareId)
        default:
            return true
        }
    }
}

// MARK: - SortTypeListViewModelDelegate

extension CredentialsViewModel: SortTypeListViewModelDelegate {
    func sortTypeListViewDidSelect(_ sortType: SortType) {
        selectedSortType = sortType
    }
}

// MARK: - VaultsProvider

extension CredentialsViewModel: VaultsProvider {
    func getAllVaults() async -> [Vault] {
        vaults
    }
}

extension Plan.PlanType {
    var searchBarPlaceholder: String {
        switch self {
        case .free:
            #localized("Search in oldest 2 vaults")
        default:
            #localized("Search in all vaults")
        }
    }
}
