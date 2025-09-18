//
// SimpleLoginNoteSynchronizer.swift
// Proton Pass - Created on 05/09/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Entities

// sourcery:AutoMockable
public protocol SimpleLoginNoteSynchronizerProtocol: Sendable, Actor {
    /// Sync notes for all aliases of a given user if aliases are not in synced
    /// Return `true` if some note were synced to act accordingly (refresh items on memory)
    func syncAllAliases(userId: String) async throws -> Bool

    /// Sync notes for specific aliases of a given user (told by user events system)
    /// Return `true` if some note were synced to act accordingly (refresh items on memory)
    func syncAliases(userId: String, aliases: [any ItemIdentifiable]) async throws -> Bool
}

public actor SimpleLoginNoteSynchronizer: SimpleLoginNoteSynchronizerProtocol {
    private let remoteDatasource: any RemoteAliasDatasourceProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let pageSize: Int

    public init(remoteDatasource: any RemoteAliasDatasourceProtocol,
                itemRepository: any ItemRepositoryProtocol,
                pageSize: Int = 100) {
        self.remoteDatasource = remoteDatasource
        self.itemRepository = itemRepository
        self.pageSize = pageSize
    }
}

public extension SimpleLoginNoteSynchronizer {
    func syncAllAliases(userId: String) async throws -> Bool {
        let aliases = try await itemRepository.getUnsyncedSimpleLoginNoteAliases(userId: userId)
        guard !aliases.isEmpty else { return false }
        try await groupByShareIdAndSyncInBatch(userId: userId, aliases: aliases)
        return true
    }

    func syncAliases(userId: String, aliases: [any ItemIdentifiable]) async throws -> Bool {
        guard !aliases.isEmpty else { return false }
        let items = try await itemRepository.getItems(aliases)
        assert(aliases.count == items.count, "Can not fully get all local aliases to sync notes")
        try await groupByShareIdAndSyncInBatch(userId: userId, aliases: items)
        return true
    }
}

private extension SimpleLoginNoteSynchronizer {
    func groupByShareIdAndSyncInBatch(userId: String,
                                      aliases: [SymmetricallyEncryptedItem]) async throws {
        let batchSync: @Sendable ([SymmetricallyEncryptedItem], String) async throws
            -> Void = { [weak self] aliases, _ in
                guard let self else { return }

                for chunk in aliases.chunked(into: pageSize) {
                    let details = try await remoteDatasource.getAliasDetails(userId: userId,
                                                                             items: chunk)
                    try await itemRepository.updateCachedAliasInfo(userId: userId,
                                                                   items: chunk,
                                                                   aliases: details)
                }
            }

        try await aliases.groupAndBulkAction(by: \.shareId,
                                             shouldInclude: { _ in true },
                                             action: batchSync)
    }
}
