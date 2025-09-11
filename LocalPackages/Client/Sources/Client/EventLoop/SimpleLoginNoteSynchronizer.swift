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

/// In order to sync SimpleLogin note for aliases, we need to sync in batch and jitter to not overloading the BE
/// This synchronizer takes into account current active user and sync the first page of unsynced aliases for this
/// user
/// It doesn't automatically schedule next sync
public protocol SimpleLoginNoteSynchronizerProtocol: Sendable, Actor {
    /// Report `true` if a sync is still in progress in order to not fire another one
    var isSyncing: Bool { get }

    /// Return `true` if some note were synced to refresh items on memory
    func sync() async throws -> Bool
}

public actor SimpleLoginNoteSynchronizer: SimpleLoginNoteSynchronizerProtocol {
    private let userManager: any UserManagerProtocol
    private let remoteDatasource: any RemoteAliasDatasourceProtocol
    private let localDatasource: any LocalItemDatasourceProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let pageSize: Int

    public private(set) var isSyncing = false

    public init(userManager: any UserManagerProtocol,
                remoteDatasource: any RemoteAliasDatasourceProtocol,
                localDatasource: any LocalItemDatasourceProtocol,
                itemRepository: any ItemRepositoryProtocol,
                pageSize: Int = 100) {
        self.userManager = userManager
        self.remoteDatasource = remoteDatasource
        self.localDatasource = localDatasource
        self.itemRepository = itemRepository
        self.pageSize = pageSize
    }
}

public extension SimpleLoginNoteSynchronizer {
    func sync() async throws -> Bool {
        defer { isSyncing = false }
        isSyncing = true
        let userId = try await userManager.getActiveUserId()
        let unsyncedAliases =
            try await localDatasource.getUnsyncedSimpleLoginNoteAliases(userId: userId,
                                                                        pageSize: pageSize)

        guard !unsyncedAliases.isEmpty else {
            return false
        }
        let details = try await remoteDatasource.getAliasDetails(userId: userId,
                                                                 items: unsyncedAliases)
        try await itemRepository.updateCachedAliasInfo(userId: userId,
                                                       items: unsyncedAliases,
                                                       aliases: details)
        return true
    }
}
