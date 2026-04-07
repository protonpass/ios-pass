//
// DeleteLocalDataBeforeFullSync.swift
// Proton Pass - Created on 27/11/2023.
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

/// We don't drop the database/delete everything because that would delete user state
/// (search history, telemetry events, public keys...)
///
/// But we need to make sure that all data encrypted by a local symmetric key is deleted
/// (items, shares, share keys...)
public protocol DeleteLocalDataBeforeFullSyncUseCase: Sendable {
    func execute(userId: String) async throws
}

public extension DeleteLocalDataBeforeFullSyncUseCase {
    func callAsFunction(userId: String) async throws {
        try await execute(userId: userId)
    }
}

public final class DeleteLocalDataBeforeFullSync: DeleteLocalDataBeforeFullSyncUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let shareKeyRepository: any ShareKeyRepositoryProtocol
    private let folderKeyDatasource: any LocalFolderKeyDatasourceProtocol
    private let folderRepository: any FolderRepositoryProtocol

    public init(itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                shareKeyRepository: any ShareKeyRepositoryProtocol,
                folderKeyDatasource: any LocalFolderKeyDatasourceProtocol,
                folderRepository: any FolderRepositoryProtocol) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.shareKeyRepository = shareKeyRepository
        self.folderKeyDatasource = folderKeyDatasource
        self.folderRepository = folderRepository
    }

    public func execute(userId: String) async throws {
        async let deletingLocalItems: Void = itemRepository.deleteAllUserItemsLocally(userId: userId)
        async let deletingLocalShares: Void = shareRepository.deleteAllUserSharesLocally(userId: userId)
        async let deletingLocalShareKeys: Void = shareKeyRepository
            .deleteAllUserShareKeysLocally(userId: userId)
        async let deletingLocalFolderKeys: Void = folderKeyDatasource.removeAllKeys(userId: userId)
        async let deletingLocalFolders: Void = folderRepository.deleteAllLocalFolders(userId: userId)
        _ = try await (deletingLocalItems,
                       deletingLocalShares,
                       deletingLocalShareKeys,
                       deletingLocalFolderKeys,
                       deletingLocalFolders)
    }
}
