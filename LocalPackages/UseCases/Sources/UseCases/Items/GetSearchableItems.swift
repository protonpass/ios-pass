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
        async let getShares = shareRepository.getDecryptedShares(userId: userId)
        async let getSymmetricKey = symmetricKeyProvider.getSymmetricKey()
        let (shares, symmetricKey) = try await (getShares, getSymmetricKey)
        let vaults = dedupShare(shares: shares, filterHidden: true)
        let context = DecryptionContext(symmetricKey: symmetricKey, vaults: vaults)

        switch searchMode {
        case .pinned:
            try Task.checkCancellation()
            let pinned = try await getAllPinnedItems()
            return try await .init(scoped: decrypt(pinned, context: context), all: nil)

        case let .all(shareSelection):
            return try await searchableItems(userId: userId,
                                             shareSelection: shareSelection,
                                             context: context)
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

    struct ActiveSet {
        let decrypted: [SearchableItem]
        let encrypted: [SymmetricallyEncryptedItem]

        func filtered(by predicate: (SymmetricallyEncryptedItem) -> Bool) -> [SearchableItem] {
            let ids = Set(encrypted.filter(predicate).map(\.ids))
            return decrypted.filter { ids.contains($0.ids) }
        }
    }

    func searchableItems(userId: String,
                         shareSelection: ShareSelection,
                         context: DecryptionContext) async throws -> SearchableItems {
        switch shareSelection {
        case .all:
            try Task.checkCancellation()
            let items = try await itemRepository.getItems(userId: userId, state: .active)
            return try await .init(scoped: decrypt(items, context: context), all: nil)

        case .trash:
            try Task.checkCancellation()
            async let getTrashed = itemRepository.getItems(userId: userId, state: .trashed)
            async let getActive = itemRepository.getItems(userId: userId, state: .active)
            let (trashed, active) = try await (getTrashed, getActive)
            return try await .init(scoped: decrypt(trashed, context: context),
                                   all: decrypt(active, context: context))

        case let .precise(selection):
            let active = try await activeSet(userId: userId, context: context)
            return await .init(scoped: scoped(active.decrypted, to: selection), all: active.decrypted)

        case .sharedByMe:
            let active = try await activeSet(userId: userId, context: context)
            return .init(scoped: active.filtered(by: \.item.isASharedByMeItem), all: active.decrypted)

        case .sharedWithMe:
            let active = try await activeSet(userId: userId, context: context)
            return .init(scoped: active.filtered(by: \.item.isASharedWithMeItem), all: active.decrypted)
        }
    }

    func activeSet(userId: String, context: DecryptionContext) async throws -> ActiveSet {
        try Task.checkCancellation()
        let encrypted = try await itemRepository.getItems(userId: userId, state: .active)
        return try await .init(decrypted: decrypt(encrypted, context: context), encrypted: encrypted)
    }

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

    func scoped(_ items: [SearchableItem],
                to selection: ShareSelectionPayload) async -> [SearchableItem] {
        let shareId = selection.share.shareId
        guard let folderId = selection.folder?.folderId else {
            return items.scoped(toShare: shareId, containerIds: nil)
        }
        return await items.scoped(toShare: shareId,
                                  containerIds: subtreeFolderIds(shareId: shareId, folderId: folderId))
    }

    func subtreeFolderIds(shareId: String, folderId: String) async -> Set<String> {
        guard let content = await appContentManager.getShareContent(for: shareId) else {
            logger.trace("Could not find subtree folder ids for \(shareId). Returning only the provided folder.")
            return [folderId]
        }
        return Set(content.flattenedFolders(from: folderId).map(\.folderId)).union([folderId])
    }
}
