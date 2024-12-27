//
// AppContentManager.swift
// Proton Pass - Created on 07/03/2023.
// Copyright (c) 2023 Proton Technologies AG
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
@preconcurrency import Combine
import Core
@preconcurrency import CryptoKit
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreLogin
import SwiftUI

enum AppContentState: Equatable {
    case loading
    case loaded(SharesData)
    case error(any Error)

    var loadedContent: SharesData? {
        switch self {
        case let .loaded(content):
            content
        default:
            nil
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            true
        case let (.loaded(lhsUiModel), .loaded(rhsUiModel)):
            lhsUiModel.hashValue == rhsUiModel.hashValue
        case let (.error(lhsError), .error(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }
}

final class AppContentManager: ObservableObject, @unchecked Sendable, DeinitPrintable, AppContentManagerProtocol {
    deinit { print(deinitMessage) }

    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)
    @LazyInjected(\SharedToolingContainer.preferencesManager) private var preferencesManager

    private let queue = DispatchQueue(label: "me.proton.pass.vaultsManager")
    private var safeIsRefreshing = false
    private var isRefreshing: Bool {
        get {
            queue.sync {
                safeIsRefreshing
            }
        }
        set {
            queue.sync {
                safeIsRefreshing = newValue
            }
        }
    }

    // Use cases
    private let indexAllLoginItems = resolve(\SharedUseCasesContainer.indexAllLoginItems)
    private let indexItemsForSpotlight = resolve(\SharedUseCasesContainer.indexItemsForSpotlight)
    private let deleteLocalDataBeforeFullSync = resolve(\SharedUseCasesContainer.deleteLocalDataBeforeFullSync)

    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var state = AppContentState.loading
    @Published private(set) var vaultSelection = VaultSelection.all
    @Published private(set) var itemCount = ItemCount.zero

    @AppStorage(Constants.filterTypeKey, store: kSharedUserDefaults)
    private(set) var filterOption = ItemTypeFilterOption.all

    @AppStorage(Constants.incompleteFullSyncUserId, store: kSharedUserDefaults)
    private(set) var incompleteFullSyncUserId: String?

    nonisolated let currentVaults: CurrentValueSubject<[Share], Never> = .init([])
    // Should subscribe and receive on main queue in view models to be sure not crash appears between @MainActor
    // isolation and combine
    nonisolated let vaultSyncEventStream = PassthroughSubject<VaultSyncProgressEvent, Never>()
    nonisolated let currentSpotlightSelectedVaults: CurrentValueSubject<[Share], Never> = .init([])

    // The filter option after switching vaults
    private var pendingItemTypeFilterOption: ItemTypeFilterOption?

    init() {
        setUp()
    }

    var hasOnlyOneOwnedVault: Bool {
        getAllShares().numberOfOwnedVault <= 1
    }

    @MainActor
    func reset() {
        state = .loading
        vaultSelection = .all
        itemCount = .zero
        currentVaults.send([])
        vaultSyncEventStream.send(.initialization)
    }
}

// MARK: - Data loading Public APIs

extension AppContentManager {
    @MainActor
    func refresh(userId: String) async throws {
        guard !isRefreshing else { return }
        defer { isRefreshing = false }
        do {
            // No need to show loading indicator once items are loaded beforehand.
            var cryptoErrorOccured = false
            switch state {
            case .loaded:
                break
            case let .error(error):
                cryptoErrorOccured = error is CryptoKitError
                state = .loading
            default:
                state = .loading
            }

            if await loginMethod.isManualLogIn() {
                logger.info("Manual login, doing full sync")
                await fullSync(userId: userId)
                await loginMethod.setLogInFlow(newState: false)
                logger.info("Manual login, done full sync")
            } else if cryptoErrorOccured {
                logger.info("Crypto error occurred. Doing full sync")
                await fullSync(userId: userId)
                logger.info("Crypto error occurred. Done full sync")
            } else {
                logger.info("Not manual login, getting local shares & items")
                let shares = try await shareRepository.getDecryptedShares(userId: userId)
                try await loadContents(userId: userId, for: shares)
                logger.info("Not manual login, done getting local shares & items")
            }
        } catch {
            state = .error(error)
        }
    }

    // Delete everything and download again
    func fullSync(userId: String) async {
        vaultSyncEventStream.send(.started)

        incompleteFullSyncUserId = userId

        do {
            // 1. Delete all local data
            try await deleteLocalDataBeforeFullSync()

            // 2. Get all remote shares and their items
            let remoteShares = try await shareRepository.getDecryptedRemoteShares(userId: userId)
            vaultSyncEventStream.send(.downloadedShares(remoteShares.representingVaults))

            try await withThrowingTaskGroup(of: Void.self) { taskGroup in
                // Step 1: Upsert all shares in a single batch
                async let upsertSharesTask: Void = shareRepository.upsertShares(userId: userId,
                                                                                shares: remoteShares,
                                                                                eventStream: vaultSyncEventStream)

                // Step 2: Process each share's items concurrently
                for share in remoteShares {
                    taskGroup.addTask { [weak self] in
                        guard let self else { return }
                        try await itemRepository.refreshItems(userId: userId,
                                                              shareId: share.shareID,
                                                              eventStream: vaultSyncEventStream)
                    }
                }

                // Wait for both the upsert task and all item processing tasks to complete
                _ = try await (upsertSharesTask, taskGroup.waitForAll())
            }

            // 3. Create default vault if no vaults
            if remoteShares.isEmpty {
                try await createDefaultVault()
            }

            try await loadContents(userId: userId, for: remoteShares)
        } catch {
            vaultSyncEventStream.send(.error(userId: userId, error: error))
            return
        }

        incompleteFullSyncUserId = nil
        vaultSyncEventStream.send(.done)
    }

    func localFullSync(userId: String) async throws {
        let shares = try await shareRepository.getDecryptedShares(userId: userId)
        state = .loading
        try await loadContents(userId: userId, for: shares)
    }
}

// MARK: - Share Actions Public APIs

extension AppContentManager {
    func select(_ selection: VaultSelection, filterOption: ItemTypeFilterOption? = nil) {
        pendingItemTypeFilterOption = filterOption
        vaultSelection = selection

        Task { [weak self] in
            guard let self else { return }
            do {
                try await preferencesManager.updateUserPreferences(\.lastSelectedShareId,
                                                                   value: selection.preferenceKey)
            } catch {
                logger.error(error)
            }
        }
    }

    func isSelected(_ selection: VaultSelection) -> Bool {
        vaultSelection == selection
    }

    func getShareContent(for shareId: String) -> ShareContent? {
        guard let sharesData = state.loadedContent else { return nil }
        return sharesData.shares.first { $0.share.id == shareId }
    }

    func getAllSharesContent() -> [ShareContent] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares
    }

    func getAllShares() -> [Share] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares.map(\.share)
    }

    func getAllSharesLinkToVault() -> [Share] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.filteredOrderedVaults
    }

    func getAllSharesWithVaultContent() -> [ShareContent] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares.filter { $0.share.vaultContent != nil }
    }

    func getAllEditableVaultContents() -> [ShareContent] {
        getAllSharesContent().filter { $0.share.vaultContent != nil && $0.share.canEdit }
    }

    func delete(vault: Share) async throws {
        let shareId = vault.shareId
        logger.trace("Deleting vault \(shareId)")
        try await shareRepository.deleteVault(shareId: shareId)
        logger.trace("Deleting local active items of vault \(shareId)")
        try await itemRepository.deleteAllItemsLocally(shareId: shareId)
        // Delete local items of the vault
        logger.info("Deleted vault \(shareId)")
    }

    func delete(userId: String, shareId: String) async throws {
        logger.trace("Deleting share \(shareId)")
        try await shareRepository.deleteShare(userId: userId, shareId: shareId)
        try await shareRepository.deleteShareLocally(userId: userId, shareId: shareId)
        logger.trace("Deleting local active items of share \(shareId)")
        try await itemRepository.deleteAllItemsLocally(shareId: shareId)
        logger.info("Deleted vault \(shareId)")
    }

    func getOldestOwnedVault() -> Share? {
        guard let sharesData = state.loadedContent else { return nil }
        let shares = sharesData.shares.map(\.share)
        return shares.oldestOwned
    }
}

// MARK: - Items Actions Public APIs

extension AppContentManager {
    func getItems(for vault: Share) -> [ItemUiModel] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares.first { $0.share.id == vault.id }?.items ?? []
    }

    func getAllActiveAndTrashedItems() -> [ItemUiModel] {
        guard let sharesData = state.loadedContent else { return [] }
        let activeItems = sharesData.shares.flatMap(\.items)
        return activeItems + sharesData.trashedItems
    }

    func getAllSharesItems() -> [ItemUiModel] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares.flatMap(\.items)
    }

    func getItemContent(shareId: String, itemId: String) async throws -> ItemContent? {
        try await itemRepository.getItemContent(shareId: shareId, itemId: itemId)
    }

    @MainActor
    func updateItemTypeFilterOption(_ filterOption: ItemTypeFilterOption) {
        self.filterOption = filterOption
    }

    func getFilteredItems() -> [ItemUiModel] {
        guard let sharesData = state.loadedContent else { return [] }
        let items: [ItemUiModel] = switch vaultSelection {
        case .all:
            sharesData.shares.flatMap(\.items)
        case let .precise(selectedVault):
            sharesData.shares
                .filter { $0.share.shareId == selectedVault.shareId }
                .flatMap(\.items)
        case .sharedByMe:
            sharesData.itemsSharedByMe
        case .sharedWithMe:
            sharesData.itemsSharedWithMe
        case .trash:
            sharesData.trashedItems
        }

        switch filterOption {
        case .all:
            return items
        case let .precise(type):
            return items.filter { $0.type == type }
        case .itemSharedWithMe:
            return sharesData.itemsSharedWithMe
        case .itemSharedByMe:
            return sharesData.itemsSharedByMe
        }
    }

    func isItemVisible(_ item: any ItemIdentifiable, type: ItemContentType) -> Bool {
        switch vaultSelection {
        case .all:
            true
        case let .precise(vault):
            if vault.shareId == item.shareId {
                switch filterOption {
                case let .precise(filterType):
                    filterType == type
                default:
                    true
                }
            } else {
                false
            }
        default:
            false
        }
    }

    func restoreAllTrashedItems(userId: String) async throws {
        logger.trace("Restoring all trashed items")
        let trashedItems = try await getAllEditableTrashedItems(userId: userId)
        try await itemRepository.untrashItems(trashedItems)
        logger.info("Restored all trashed items")
    }

    func permanentlyDeleteAllTrashedItems(userId: String) async throws {
        logger.trace("Permanently deleting all trashed items")
        let trashedItems = try await getAllEditableTrashedItems(userId: userId)
        try await itemRepository.deleteItems(userId: userId, trashedItems, skipTrash: false)
        logger.info("Permanently deleted all trashed items")
    }
}

// MARK: - LimitationCounterProtocol

extension AppContentManager: LimitationCounterProtocol {
    func getAliasCount() -> Int {
        switch state {
        case let .loaded(sharesData):
            let activeAliases = sharesData.shares.flatMap(\.items).filter(\.isAlias)
            let trashedAliases = sharesData.trashedItems.filter(\.isAlias)
            return activeAliases.count + trashedAliases.count
        default:
            return 0
        }
    }

    func getTOTPCount() -> Int {
        guard let sharesData = state.loadedContent else { return 0 }
        let activeItemsWithTotpUri = sharesData.shares.flatMap(\.items).filter(\.hasTotpUri).count
        let trashedItemsWithTotpUri = sharesData.trashedItems.filter(\.hasTotpUri).count
        return activeItemsWithTotpUri + trashedItemsWithTotpUri
    }

    func getSharesCount() -> Int {
        guard let sharesData = state.loadedContent else { return 0 }
        return sharesData.shares.count
    }

    func getVaultsCount() -> Int {
        guard let sharesData = state.loadedContent else { return 0 }
        return sharesData.filteredOrderedVaults.count
    }
}

// MARK: - Private APIs

private extension AppContentManager {
    func setUp() {
        $state
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                updateItemCount()
            }
            .store(in: &cancellables)

        $vaultSelection
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                filterOption = pendingItemTypeFilterOption ?? .all
                pendingItemTypeFilterOption = nil
                updateItemCount()
            }
            .store(in: &cancellables)
    }

    func updateItemCount() {
        guard let sharesData = state.loadedContent else { return }
        var sharedByMe = 0
        var sharedWithMe = 0
        var items: [any ItemTypeIdentifiable] = []
        switch vaultSelection {
        case .all:
            items = sharesData.shares.flatMap(\.items)
            sharedByMe = sharesData.itemsSharedByMe.count
            sharedWithMe = sharesData.itemsSharedWithMe.count
        case let .precise(selectedShare):
            let filteredShare = sharesData.shares
                .filter { $0.id == selectedShare.id }
            items = filteredShare
                .flatMap(\.items)
            sharedByMe = filteredShare
                .filter { !$0.share.isVaultRepresentation && $0.share.owner }
                .flatMap(\.items).count
            sharedWithMe = filteredShare
                .filter { !$0.share.isVaultRepresentation && !$0.share.owner }.flatMap(\.items).count
        case .sharedByMe:
            items = sharesData.itemsSharedByMe
            sharedByMe = sharesData.itemsSharedByMe.count
            sharedWithMe = 0
        case .sharedWithMe:
            items = sharesData.itemsSharedWithMe
            sharedByMe = 0
            sharedWithMe = sharesData.itemsSharedWithMe.count
        case .trash:
            items = sharesData.trashedItems
        }

        itemCount = .init(items: items, sharedByMe: sharedByMe, sharedWithMe: sharedWithMe)
    }

    func createDefaultVault() async throws {
        logger.trace("Creating default vault for user")
        let vault = VaultContent(name: #localized("Personal"),
                                 description: #localized("Personal"),
                                 color: .color1,
                                 icon: .icon1)
        try await shareRepository.createVault(vault)
        logger.info("Created default vault for user")
    }

    @MainActor
    func loadContents(userId: String, for shares: [Share]) async throws {
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let allItems = try await itemRepository.getAllItems(userId: userId)

        let sharesData = try await getShareDatas(symmetricKey: symmetricKey,
                                                 shares: shares,
                                                 items: allItems)
        let userPreferences = preferencesManager.userPreferences.unwrapped()

        currentVaults.send(shares)
        state = .loaded(sharesData)

        if let lastSelectedShareId = userPreferences.lastSelectedShareId {
            if lastSelectedShareId == VaultSelection.sharedByMe.preferenceKey, vaultSelection != .sharedByMe {
                vaultSelection = .sharedByMe
            } else if lastSelectedShareId == VaultSelection.sharedWithMe.preferenceKey,
                      vaultSelection != .sharedWithMe {
                vaultSelection = .sharedWithMe
            } else if lastSelectedShareId == VaultSelection.trash.preferenceKey, vaultSelection != .trash {
                vaultSelection = .trash
            } else if let vault = shares.first(where: { $0.shareId == lastSelectedShareId }) {
                vaultSelection = .precise(vault)
            }
        } else {
            vaultSelection = .all
        }

        indexContent(userPreferences: userPreferences)
    }

    func indexForAutoFill() async {
        if preferencesManager.sharedPreferences.unwrapped().quickTypeBar {
            do {
                try await indexAllLoginItems()
            } catch {
                logger.error(error)
            }
        }
    }

    func getAllEditableTrashedItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        let editableShareIds = getAllEditableVaultContents().map(\.share.shareId)
        let trashedItems = try await itemRepository.getItems(userId: userId, state: .trashed)
        return trashedItems.filter { item in
            editableShareIds.contains(where: { $0 == item.shareId })
        }
    }

    func getShareDatas(symmetricKey: SymmetricKey,
                       shares: [Share],
                       items: [SymmetricallyEncryptedItem]) async throws -> SharesData {
        // Group items by their associated share ID for efficient processing
        let itemsByShareID = Dictionary(grouping: items, by: { $0.shareId })

        return try await withThrowingTaskGroup(of: (ShareContent, [ItemUiModel]).self) { @Sendable taskGroup in
            var shareContents: [ShareContent] = []
            var trashedItems: [ItemUiModel] = []
            for share in shares {
                taskGroup.addTask { @Sendable in
                    // Retrieve items linked to this share
                    let shareItems = itemsByShareID[share.id] ?? []

                    // Decrypt items and classify them
                    var activeItems: [ItemUiModel] = []
                    var trashItems: [ItemUiModel] = []

                    for encryptedItem in shareItems {
                        let decryptedItem = try encryptedItem.toItemUiModel(symmetricKey)
                        // Separate active and inactive items
                        if decryptedItem.state == .active {
                            activeItems.append(decryptedItem)
                        } else {
                            trashItems.append(decryptedItem)
                        }
                    }

                    let shareContent = ShareContent(share: share, items: activeItems)
                    return (shareContent, trashItems)
                }
            }

            // Aggregate results from all tasks
            for try await (shareContent, trashItems) in taskGroup {
                shareContents.append(shareContent)
                trashedItems.append(contentsOf: trashItems)
            }

            return SharesData(shares: shareContents, trashedItems: trashedItems)
        }
    }

    func indexContent(userPreferences: UserPreferences) {
        Task {
            do {
                async let indexForAutoFill: Void = indexForAutoFill()
                async let indexItemsForSpotlight: Void = indexItemsForSpotlight(userPreferences)

                _ = try await (indexForAutoFill, indexItemsForSpotlight)
            } catch {
                logger.error(message: "Failed indexing content for auto fill and spotlight", error: error)
            }
        }
    }
}
