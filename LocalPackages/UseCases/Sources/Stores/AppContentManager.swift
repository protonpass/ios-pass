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
import Foundation
import Macro
import ProtonCoreLogin
import SwiftUI
import UseCases

public enum AppContentState: Equatable {
    case loading
    case loaded(SharesData)
    case error(any Error)

    public var loadedContent: SharesData? {
        switch self {
        case let .loaded(content):
            content

        default:
            nil
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
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

@MainActor
public final class AppContentManager: ObservableObject, DeinitPrintable, AppContentManagerProtocol {
    deinit { print(deinitMessage) }

    @Published public private(set) var state = AppContentState.loading
    @Published public private(set) var shareSelection = ShareSelection.all
    @Published public private(set) var itemCount = ItemCount.zero

    @AppStorage(Constants.filterTypeKey, store: kSharedUserDefaults)
    public private(set) var filterOption = ItemTypeFilterOption.all

    @AppStorage(Constants.incompleteFullSyncUserId, store: kSharedUserDefaults)
    public private(set) var incompleteFullSyncUserId: String?

    public nonisolated let currentShares: CurrentValueSubject<[Share], Never> = .init([])

    public nonisolated let vaultSyncEventStream = PassthroughSubject<VaultSyncProgressEvent, Never>()
    public nonisolated let currentSpotlightSelectedVaults: CurrentValueSubject<[Share], Never> = .init([])

    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let logger: Logger
    private let loginMethod: LoginMethodFlow
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let preferencesManager: any PreferencesManagerProtocol
    private let inviteRepository: any FullInviteRepositoryProtocol
    private let slNoteSynchronizer: any SimpleLoginNoteSynchronizerProtocol
    private let folderRepository: any FolderRepositoryProtocol

    // Use cases
    private let indexAllLoginItems: any IndexAllLoginItemsUseCase
    private let indexItemsForSpotlight: any IndexItemsForSpotlightUseCase
    private let deleteLocalDataBeforeFullSync: any DeleteLocalDataBeforeFullSyncUseCase
    private let getLastEventIdIfNotExist: any GetLastEventIdIfNotExistUseCase
    private let getFeatureFlagStatus: any GetFeatureFlagStatusUseCase
    private let dedupShare: any DedupShareUseCase
    private let refreshUserData: any RefreshUserDataUseCase

    private var cancellables = Set<AnyCancellable>()
    private var refreshingUserId: String?
    private var pendingRefreshUserId: String?
    /// The filter option after switching vaults
    private var pendingItemTypeFilterOption: ItemTypeFilterOption?

    public var hasEditableContainers: Bool {
        getAllShares().contains {
            $0.shareType != .item && $0.canEdit
        }
    }

    public init(itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                inviteRepository: any FullInviteRepositoryProtocol,
                folderRepository: any FolderRepositoryProtocol,
                slNoteSynchronizer: any SimpleLoginNoteSynchronizerProtocol,
                preferencesManager: any PreferencesManagerProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                indexAllLoginItems: any IndexAllLoginItemsUseCase,
                indexItemsForSpotlight: any IndexItemsForSpotlightUseCase,
                deleteLocalDataBeforeFullSync: any DeleteLocalDataBeforeFullSyncUseCase,
                getLastEventIdIfNotExist: any GetLastEventIdIfNotExistUseCase,
                getFeatureFlagStatus: any GetFeatureFlagStatusUseCase,
                dedupShare: any DedupShareUseCase,
                refreshUserData: any RefreshUserDataUseCase,
                logger: Logger,
                loginMethod: LoginMethodFlow) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.inviteRepository = inviteRepository
        self.folderRepository = folderRepository
        self.slNoteSynchronizer = slNoteSynchronizer
        self.preferencesManager = preferencesManager
        self.symmetricKeyProvider = symmetricKeyProvider
        self.indexAllLoginItems = indexAllLoginItems
        self.indexItemsForSpotlight = indexItemsForSpotlight
        self.deleteLocalDataBeforeFullSync = deleteLocalDataBeforeFullSync
        self.getLastEventIdIfNotExist = getLastEventIdIfNotExist
        self.getFeatureFlagStatus = getFeatureFlagStatus
        self.dedupShare = dedupShare
        self.refreshUserData = refreshUserData
        self.logger = logger
        self.loginMethod = loginMethod
        setUp()
    }

    public var hasOnlyOneOwnedVault: Bool {
        getAllShares().numberOfOwnedVault <= 1
    }

    public func reset() {
        state = .loading
        shareSelection = .all
        itemCount = .zero
        currentShares.send([])
        vaultSyncEventStream.send(.initialization)
    }
}

// MARK: - Data loading Public APIs

public extension AppContentManager {
    func refresh(userId: String) async {
        guard refreshingUserId == nil else {
            pendingRefreshUserId = userId
            return
        }
        refreshingUserId = userId
        defer {
            refreshingUserId = nil
            if let pending = pendingRefreshUserId {
                pendingRefreshUserId = nil
                Task { [weak self] in
                    guard let self else { return }
                    await refresh(userId: pending)
                }
            }
        }
        do {
            // No need to show loading indicator once items are loaded beforehand.
            var cryptoErrorOccurred = false
            switch state {
            case .loaded:
                break

            case let .error(error):
                cryptoErrorOccurred = error is CryptoKitError
                state = .loading

            default:
                state = .loading
            }

            if await loginMethod.isManualLogIn() {
                logger.info("Manual login, doing full sync")
                await fullSync(userId: userId)
                await loginMethod.setLogInFlow(newState: false)
                logger.info("Manual login, done full sync")
            } else if cryptoErrorOccurred {
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
            logger.error(message: "Failed to refresh content for user \(userId)", error: error)
            state = .error(error)
        }
    }

    /// Delete everything and download again
    func fullSync(userId: String) async {
        vaultSyncEventStream.send(.started)

        incompleteFullSyncUserId = userId
        var hasUndecryptableShares = false
        do {
            // 0. Refresh user data to handle account changes like added address keys
            try await refreshUserData(userId: userId)

            // 1. Delete all local data
            try await deleteLocalDataBeforeFullSync(userId: userId)

            // 2. Get all remote shares and their items
            let remoteShares = try await shareRepository.getDecryptedRemoteShares(userId: userId)
            hasUndecryptableShares = remoteShares.hasUndecryptableShares
            vaultSyncEventStream.send(.downloadedShares(remoteShares.shares.representingVaults))

            try await withThrowingTaskGroup(of: Void.self) { taskGroup in
                // Step 1: Upsert all shares in a single batch
                async let upsertSharesTask: Void = shareRepository.upsertShares(userId: userId,
                                                                                shares: remoteShares.shares,
                                                                                eventStream: vaultSyncEventStream)

                // Step 2: Process each share's folders and items concurrently
                for share in remoteShares.shares {
                    taskGroup.addTask { [weak self] in
                        guard let self else { return }
                        if share.shareType == .vault {
                            try await folderRepository.refreshFolders(userId: userId,
                                                                      shareId: share.shareID)
                        }

                        try await itemRepository.refreshItems(userId: userId,
                                                              shareId: share.shareID,
                                                              eventStream: vaultSyncEventStream)
                    }
                }

                // Wait for both the upsert task and all item processing tasks to complete
                _ = try await (upsertSharesTask, taskGroup.waitForAll())
            }

            // 3. Create default vault if no vaults
            if remoteShares.shares.representingVaults.isEmpty {
                do {
                    try await createDefaultVault()
                } catch {
                    guard let apiError = error.asPassApiError,
                          apiError == .notAllowed else {
                        throw error
                    }
                    // Can't create default vault because of B2B policy
                    // Do nothing and just move on
                }
            }

            // 4. Refresh invite and sl notes
            if getFeatureFlagStatus(for: FeatureFlagType.passUserEventsV1) {
                async let syncAliases: Bool = slNoteSynchronizer.syncAllAliases(userId: userId)
                async let refreshInvites: Void = inviteRepository.refreshAllInvites(userId: userId)
                do {
                    _ = try await (syncAliases, refreshInvites)
                } catch {
                    // We logs the errors silently to let the full content refresh continue offering a better
                    // experience to the user.
                    logger.error(error)
                }
            }

            try await loadContents(userId: userId, for: remoteShares.shares)

            // 5. Get the lastEventID as a starting point for user events sync loop
            try await getLastEventIdIfNotExist(userId: userId)
        } catch {
            vaultSyncEventStream.send(.error(userId: userId, error: error))
            return
        }

        incompleteFullSyncUserId = nil
        vaultSyncEventStream.send(.done(hasUndecryptableShares: hasUndecryptableShares))
    }

    func localFullSync(userId: String) async throws {
        let shares = try await shareRepository.getDecryptedShares(userId: userId)
        state = .loading
        try await loadContents(userId: userId, for: shares)
    }
}

// MARK: - Share Actions Public APIs

public extension AppContentManager {
    func select(_ selection: ShareSelection, filterOption: ItemTypeFilterOption?) {
        pendingItemTypeFilterOption = filterOption
        shareSelection = selection

        Task { [weak self] in
            guard let self else { return }
            do {
                let selectedShareId = selection.selectedShareId ?? selection.preferenceKey
                try await preferencesManager.updateUserPreferences(\.lastSelectedShareId,
                                                                   value: selectedShareId)
                try await preferencesManager.updateUserPreferences(\.lastSelectedFolderId,
                                                                   value: selection.preciseSelectionPayload?
                                                                       .folder?.id)
            } catch {
                logger.error(error)
            }
        }
    }

    func isSelected(_ selection: ShareSelection) -> Bool {
        shareSelection == selection
    }

    func getShareContent(for shareId: String) -> ShareContent? {
        guard let sharesData = state.loadedContent else { return nil }
        return sharesData.shares[shareId]
    }

    func getAllSharesContent() -> [ShareContent] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares.map(\.value)
    }

    func getAllShares() -> [Share] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares.values.map(\.share)
    }

    func getAllSharesLinkToVault() -> [Share] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.filteredOrderedVaults.map(\.share)
    }

    func getAllSharesWithVaultContent() -> [ShareContent] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares.values.filter { $0.share.vaultContent != nil }
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

    func deleteFolder(userId: String, shareId: String, folderId: String) async throws {
        guard let sharesData = state.loadedContent,
              let shareContent = sharesData.shares[shareId] else { return }

        logger.trace("Deleting folder \(folderId)")
        try await folderRepository.delete(userId: userId, shareId: shareId, folderIds: [folderId])
        logger.trace("Deleting local active items of folder and subfolders \(folderId)")
        let itemIds = shareContent.flattenedItems(from: folderId).map(\.itemId)
        let folderIds = shareContent.flattenedFolders(from: folderId).map(\.folderId)
        async let deletingFolders: Void = folderIds.isEmpty ? () : folderRepository
            .deleteLocalFolders(userId: userId,
                                shareId: shareId,
                                folderIds: folderIds)
        async let deletingItems: Void = itemIds.isEmpty ? () : itemRepository.deleteItemsLocally(itemIds: itemIds,
                                                                                                 shareId: shareId)
        _ = try await (deletingFolders, deletingItems)
        logger.info("Deleted folder \(folderId)")
    }

    func delete(userId: String, shareId: String) async throws {
        logger.trace("Deleting share \(shareId)")
        try await shareRepository.deleteShare(userId: userId, shareId: shareId)
        try await shareRepository.deleteShareLocally(userId: userId, shareId: shareId)
        logger.trace("Deleting local active items of share \(shareId)")
        try await itemRepository.deleteAllItemsLocally(shareId: shareId)
        logger.info("Deleted share \(shareId)")
    }

    func getOldestOwnedVault() -> Share? {
        guard let sharesData = state.loadedContent else { return nil }
        let shares = sharesData.shares.map(\.value.share)
        return shares.oldestOwned
    }
}

// MARK: - Items Actions Public APIs

public extension AppContentManager {
    func getAllActiveAndTrashedItems() -> [ItemUiModel] {
        guard let sharesData = state.loadedContent else { return [] }
        let activeItems = getAllSharesItems()
        return activeItems + sharesData.trashedItems
    }

    func getAllSharesItems() -> [ItemUiModel] {
        guard let sharesData = state.loadedContent else { return [] }
        return sharesData.shares.values.flatMap(\.allItems)
    }

    // periphery:ignore
    func getContent(for shareId: String, containerId: String?) -> [ShareContentElement] {
        guard let sharesData = state.loadedContent,
              let shareContent = sharesData.shares[shareId] else { return [] }

        return shareContent.elements(for: containerId ?? shareId) ?? []
    }

    func getItems(shareId: String, containerId: String?) -> [ItemUiModel] {
        guard let sharesData = state.loadedContent,
              let shareContent = sharesData.shares[shareId] else { return [] }
        return if let containerId {
            shareContent.flattenedItems(from: containerId)
        } else {
            shareContent.allItems
        }
    }

    func getItemContent(shareId: String, itemId: String) async throws -> ItemContent? {
        try await itemRepository.getItemContent(shareId: shareId, itemId: itemId)
    }

    @MainActor
    func updateItemTypeFilterOption(_ filterOption: ItemTypeFilterOption) {
        self.filterOption = filterOption
    }

    // swiftlint:disable:next cyclomatic_complexity
    func getFilteredItems() -> [ItemUiModel] {
        guard let sharesData = state.loadedContent else { return [] }

        // 1. Early exit for filter options that completely override share selection
        switch filterOption {
        case .itemSharedWithMe:
            return sharesData.itemsSharedWithMe

        case .itemSharedByMe:
            return sharesData.itemsSharedByMe

        case .all, .precise:
            break // Proceed to share selection logic
        }

        let hiddenShareIds = sharesData.hiddenSharesIds // shares.values.compactMap(\.share).hiddenShareIds

        // 2. Determine base items based on share selection
        // (hidden shares are computed lazily only when needed)
        let baseItems: [ItemUiModel] = switch shareSelection {
        case .all:
            sharesData.visibleShareContents.flatMap(\.allItems)

        case let .precise(selection):
            if let shareContent = sharesData.shares[selection.share.id] {
                shareContent.items(in: selection.folder?.folderId ?? selection.share.shareId) ?? []
            } else {
                []
            }

        case .sharedByMe:
            sharesData.itemsSharedByMe

        case .sharedWithMe:
            sharesData.itemsSharedWithMe

        case .trash:
            sharesData.trashedItems.filter { !hiddenShareIds.contains($0.shareId) }
        }

        // 3. Apply final type filter if needed
        switch filterOption {
        case .all:
            return baseItems

        case let .precise(type):
            return baseItems.filter { $0.type.isSameType(with: type) }

        case .itemSharedByMe, .itemSharedWithMe:
            assertionFailure("Unreachable: handled by early return")
            return baseItems
        }
    }

    func isItemVisible(_ item: any ItemIdentifiable, type: ItemContentType) -> Bool {
        switch shareSelection {
        case .all:
            true

        case let .precise(selection):
            if selection.share.shareId == item.shareId {
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
    public func getAliasCount() -> Int {
        switch state {
        case let .loaded(sharesData):
            let activeAliases = sharesData.shares.values.reduce(0) {
                $0 + $1.aliasCount
            } // flatMap(\.allItems).filter(\.isAlias)
            let trashedAliases = sharesData.trashedItems.compactMap(\.isAlias)
            return activeAliases + trashedAliases.count

        default:
            return 0
        }
    }

    public func getTOTPCount() -> Int {
        guard let sharesData = state.loadedContent else { return 0 }
        let activeItemsWithTotpUri = sharesData.shares.flatMap(\.value.allItems).filter(\.hasTotpUri).count
        let trashedItemsWithTotpUri = sharesData.trashedItems.compactMap(\.hasTotpUri).count
        return activeItemsWithTotpUri + trashedItemsWithTotpUri
    }

    public func getSharesCount() -> Int {
        guard let sharesData = state.loadedContent else { return 0 }
        return sharesData.shares.count
    }

    public func getVaultsCount() -> Int {
        guard let sharesData = state.loadedContent else { return 0 }
        return sharesData.vaultCount
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

        $shareSelection
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                if let pendingItemTypeFilterOption {
                    filterOption = pendingItemTypeFilterOption
                }
                pendingItemTypeFilterOption = nil
                updateItemCount()
            }
            .store(in: &cancellables)
    }

    func updateItemCount() {
        guard let sharesData = state.loadedContent else { return }
        switch shareSelection {
        case .all:
            itemCount = ItemCount(items: sharesData.shares.flatMap(\.value.allItems),
                                  sharedByMe: sharesData.itemsSharedByMe.count,
                                  sharedWithMe: sharesData.itemsSharedWithMe.count)

        case let .precise(selection):
            guard let share = sharesData.shares[selection.share.id] else {
                itemCount = ItemCount(items: [], sharedByMe: 0, sharedWithMe: 0)
                return
            }
            let items = share.allItems
            let shouldCount = !share.share.isVaultRepresentation

            if share.share.owner {
                itemCount = ItemCount(items: items, sharedByMe: shouldCount ? items.count : 0, sharedWithMe: 0)
            } else {
                itemCount = ItemCount(items: items, sharedByMe: 0, sharedWithMe: shouldCount ? items.count : 0)
            }

        case .sharedByMe:
            itemCount = ItemCount(items: sharesData.itemsSharedByMe,
                                  sharedByMe: sharesData.itemsSharedByMe.count,
                                  sharedWithMe: 0)

        case .sharedWithMe:
            itemCount = ItemCount(items: sharesData.itemsSharedWithMe,
                                  sharedByMe: 0,
                                  sharedWithMe: sharesData.itemsSharedWithMe.count)

        case .trash:
            itemCount = ItemCount(items: sharesData.trashedItems,
                                  sharedByMe: 0,
                                  sharedWithMe: 0)
        }
    }

    func createDefaultVault() async throws {
        logger.trace("Creating default vault for user")
        let vault = VaultContent(name: #localized("Personal"),
                                 description: #localized("Personal"),
                                 color: .color1,
                                 icon: .icon1)
        try await shareRepository.createVault(userId: nil, vault: vault)
        logger.info("Created default vault for user")
    }

    @MainActor
    func loadContents(userId: String, for shares: [Share]) async throws {
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()

        async let allItemsFetch = itemRepository.getAllItems(userId: userId)
        async let foldersFetch = folderRepository.getAllLocalFolders(userId: userId)

        let (allItems, folders) = try await (allItemsFetch, foldersFetch)

        let dedupShares = dedupShare(shares: shares, filterHidden: false)

        let sharesData = try await getShareDatas(symmetricKey: symmetricKey,
                                                 shares: dedupShares,
                                                 folders: folders,
                                                 items: allItems)
        let userPreferences = preferencesManager.userPreferences.unwrapped()

        currentShares.send(shares)
        state = .loaded(sharesData)

        if let lastSelectedShareId = userPreferences.lastSelectedShareId {
            if lastSelectedShareId == ShareSelection.sharedByMe.preferenceKey, shareSelection != .sharedByMe {
                shareSelection = .sharedByMe
            } else if lastSelectedShareId == ShareSelection.sharedWithMe.preferenceKey,
                      shareSelection != .sharedWithMe {
                shareSelection = .sharedWithMe
            } else if lastSelectedShareId == ShareSelection.trash.preferenceKey, shareSelection != .trash {
                shareSelection = .trash
            } else if let shareContent = sharesData.shares[lastSelectedShareId] {
                if shareContent.share.hidden {
                    // Fallback to selecting all vaults when the previous selected vault is hidden
                    shareSelection = .all
                } else {
                    let folder: FolderUiModel? = if let lastSelectedFolderId = userPreferences
                        .lastSelectedFolderId {
                        shareContent.allElements.first(where: { $0.id == lastSelectedFolderId })?.folderValue
                    } else {
                        nil
                    }

                    shareSelection = .precise(.init(share: shareContent.share, folder: folder))
                }
            }
        } else {
            shareSelection = .all
        }

        if getFeatureFlagStatus(for: FeatureFlagType.passUserEventsV1) {
            try await inviteRepository.loadLocalInvites(userId: userId)
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
                       folders: [SymmetricallyEncryptedFolder],
                       items: [SymmetricallyEncryptedItem]) async throws -> SharesData {
        // Group items by their associated share ID for efficient processing
        let itemsByShareID = Dictionary(grouping: items, by: { $0.shareId })
        let foldersByShareID = Dictionary(grouping: folders, by: { $0.shareId })
        return try await withThrowingTaskGroup(of: (ShareContent, [ItemUiModel])
            .self) { @Sendable taskGroup in
                var shareContents: [ShareContent] = []
                var trashedItems: [ItemUiModel] = []

                for share in shares {
                    taskGroup.addTask { @Sendable in
                        // Retrieve items linked to this share
                        let shareItems = itemsByShareID[share.id] ?? []
                        let shareFolders = foldersByShareID[share.id] ?? []

                        // Decrypt items and classify them
                        var shareElements: [ShareContentElement] = []
                        var trashItems: [ItemUiModel] = []

                        for encryptedItem in shareItems {
                            let decryptedItem = try encryptedItem.toItemUiModel(symmetricKey)
                            // Separate active and inactive items
                            if decryptedItem.state == .active {
                                shareElements.append(.item(decryptedItem))
                            } else {
                                trashItems.append(decryptedItem)
                            }
                        }

                        for shareFolder in shareFolders {
                            let folder = try shareFolder.toFolderUiModel(symmetricKey)
                            shareElements.append(.folder(folder))
                        }

                        let shareContent = ShareContent(share: share, elements: shareElements)
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

public extension [ShareContent] {
    func sortedByHidden() -> Self {
        sorted(by: { !$0.share.hidden && $1.share.hidden })
            .sorted { lhs, rhs in
                guard let lhsName = lhs.share.vaultName,
                      let rhsName = rhs.share.vaultName else { return false }
                return lhsName == rhsName
                    ? lhs.share.createTime < rhs.share.createTime
                    : lhsName < rhsName
            }
    }
}

// MARK: - Folders

public extension AppContentManager {
    func createFolder(userId: String, shareId: String, parentFolderId: String?, name: String) async throws {
        let content = FolderContent(name: name)
        try await folderRepository.createFolder(userId: userId,
                                                shareId: shareId,
                                                parentFolderId: parentFolderId,
                                                folderContent: content)
        try await localFullSync(userId: userId)
        try await itemRepository.refreshPinnedItemDataStream()
    }

    func editFolder(userId: String, shareId: String, folderId: String, name: String) async throws {
        let content = FolderContent(name: name)
        try await folderRepository.edit(userId: userId,
                                        shareId: shareId,
                                        folderId: folderId,
                                        folderContent: content)
        try await localFullSync(userId: userId)
        try await itemRepository.refreshPinnedItemDataStream()
    }

    func moveFolder(userId: String, shareId: String, folderId: String, newParentFolderId: String?) async throws {
        try await folderRepository.move(userId: userId,
                                        shareId: shareId,
                                        folderId: folderId,
                                        destinationId: newParentFolderId)

        try await localFullSync(userId: userId)
    }
}
