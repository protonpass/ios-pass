//
//
// GetSearchableItems.swift
// Proton Pass - Created on 30/11/2023.
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
//

import Client
import Core
@preconcurrency import CryptoKit
import Entities
import Foundation

public protocol GetSearchableItemsUseCase: Sendable {
    func execute(userId: String, for searchMode: SearchMode) async throws -> SearchableItems
}

public extension GetSearchableItemsUseCase {
    func callAsFunction(userId: String, for searchMode: SearchMode) async throws -> SearchableItems {
        try await execute(userId: userId, for: searchMode)
    }
}

public final class GetSearchableItems: GetSearchableItemsUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let getAllPinnedItems: any GetAllPinnedItemsUseCase
    private let dedupShare: any DedupShareUseCase
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let appContentManager: any AppContentManagerProtocol
    private let logger: Logger

    public init(itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                getAllPinnedItems: any GetAllPinnedItemsUseCase,
                dedupShare: any DedupShareUseCase,
                symmetricKeyProvider: any SymmetricKeyProvider,
                appContentManager: any AppContentManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.getAllPinnedItems = getAllPinnedItems
        self.dedupShare = dedupShare
        self.symmetricKeyProvider = symmetricKeyProvider
        self.appContentManager = appContentManager
        logger = .init(manager: logManager)
    }

    public func execute(userId: String, for searchMode: SearchMode) async throws -> SearchableItems {
        // The item lookups depend on neither the shares nor the key, so all three start together
        // and we only pay for the slowest.
        async let getShares = shareRepository.getDecryptedShares(userId: userId)
        async let getSymmetricKey = symmetricKeyProvider.getSymmetricKey()
        async let getItems = encryptedItems(userId: userId, searchMode: searchMode)
        let (shares, symmetricKey, items) = try await (getShares, getSymmetricKey, getItems)

        let context = DecryptionContext(symmetricKey: symmetricKey,
                                        vaults: dedupShare(shares: shares, filterHidden: true))

        switch items {
        case let .standalone(items):
            return try await .init(scoped: decrypt(items, context: context), all: nil)

        case let .disjoint(selected, active):
            return try await .init(scoped: decrypt(selected, context: context),
                                   all: decrypt(active, context: context))

        case let .subset(active, selection):
            let all = try await decrypt(active, context: context)
            let selectedIds = await Set(active.matching(selection,
                                                        subtreeFolderIds: subtreeFolderIds).map(\.ids))
            return .init(scoped: all.filter { selectedIds.contains($0.ids) }, all: all)
        }
    }
}

private extension GetSearchableItems {
    struct DecryptionContext {
        let symmetricKey: SymmetricKey
        let vaults: [Share]

        var applicableShareIds: Set<String> {
            Set(vaults.map(\.shareId))
        }
    }

    func encryptedItems(userId: String, searchMode: SearchMode) async throws -> EncryptedItems {
        try Task.checkCancellation()

        switch searchMode {
        case .pinned:
            return try await .standalone(getAllPinnedItems())

        case let .all(shareSelection):
            return try await getItems(for: shareSelection, userId: userId)
        }
    }

    func getItems(for shareSelection: ShareSelection, userId: String) async throws -> EncryptedItems {
        switch shareSelection {
        case .all:
            return try await .standalone(itemRepository.getItems(userId: userId, state: .active))

        case .trash:
            // Trashed and active items are disjoint, so this is the one selection that cannot be
            // derived from the global set and genuinely needs a second fetch.
            async let getTrashed = itemRepository.getItems(userId: userId, state: .trashed)
            async let getActive = itemRepository.getItems(userId: userId, state: .active)
            return try await .disjoint(selected: getTrashed, active: getActive)

        case let .precise(selection):
            return try await .subset(itemRepository.getItems(userId: userId, state: .active),
                                     .container(selection))

        case .sharedByMe:
            return try await .subset(itemRepository.getItems(userId: userId, state: .active), .sharedByMe)

        case .sharedWithMe:
            return try await .subset(itemRepository.getItems(userId: userId, state: .active), .sharedWithMe)
        }
    }
}

/// What a search mode needs out of the database, decided before any decryption so the fetches can
/// run alongside the share and key lookups.
private enum EncryptedItems: Sendable {
    /// One set, and no "All vaults" tab to fill.
    case standalone([SymmetricallyEncryptedItem])
    /// The selection is disjoint from the global active set, so both had to be fetched.
    case disjoint(selected: [SymmetricallyEncryptedItem], active: [SymmetricallyEncryptedItem])
    /// The selection is contained in the global active set, so it is narrowed down after a single
    /// decryption pass rather than fetched and decrypted a second time.
    case subset([SymmetricallyEncryptedItem], SubsetSelection)
}

private enum SubsetSelection: Sendable {
    case container(ShareSelectionPayload)
    case sharedByMe
    case sharedWithMe
}

private extension [SymmetricallyEncryptedItem] {
    /// Narrows the global active set while still encrypted — the shared/owned flags live only on
    /// the encrypted item, and doing it here keeps the whole derivation to one decryption pass.
    func matching(_ selection: SubsetSelection,
                  subtreeFolderIds: (String, String) async -> Set<String>) async -> Self {
        switch selection {
        case let .container(payload):
            let shareId = payload.share.shareId
            guard let folderId = payload.folder?.folderId else {
                return scoped(toShare: shareId, containerIds: nil)
            }
            return await scoped(toShare: shareId,
                                containerIds: subtreeFolderIds(shareId, folderId))

        case .sharedByMe:
            return filter(\.item.isASharedByMeItem)

        case .sharedWithMe:
            return filter(\.item.isASharedWithMeItem)
        }
    }
}

private extension GetSearchableItems {
    func decrypt(_ items: [SymmetricallyEncryptedItem],
                 context: DecryptionContext) async throws -> [SearchableItem] {
        let applicableShareIds = context.applicableShareIds
        let filteredItems = items.filter { applicableShareIds.contains($0.shareId) }
        let symmetricKey = context.symmetricKey
        let vaults = context.vaults

        return try await withThrowingTaskGroup(of: [SearchableItem].self,
                                               returning: [SearchableItem].self) { @Sendable group in
            let deviceCores = ProcessInfo.processInfo.activeProcessorCount
            let adaptiveBatchSize = max(50, min(Constants.Utils.batchSize, filteredItems.count / deviceCores))
            let itemBatches = filteredItems.chunked(into: adaptiveBatchSize)
            for batch in itemBatches {
                group.addTask { @Sendable in
                    try batch.map {
                        try Task.checkCancellation()
                        return try SearchableItem(from: $0,
                                                  symmetricKey: symmetricKey,
                                                  allVaults: vaults)
                    }
                }
            }

            var results = [SearchableItem]()
            for try await result in group {
                results.append(contentsOf: result)
            }
            return results
        }
    }

    func subtreeFolderIds(shareId: String, folderId: String) async -> Set<String> {
        guard let content = await appContentManager.getShareContent(for: shareId) else {
            logger.trace("Could not find subtree folder ids for \(shareId). Returning only the provided folder.")
            return [folderId]
        }
        return Set(content.flattenedFolders(from: folderId).map(\.folderId)).union([folderId])
    }
}
