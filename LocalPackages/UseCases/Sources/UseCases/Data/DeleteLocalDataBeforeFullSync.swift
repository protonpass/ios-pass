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
    func execute() async throws
}

public extension DeleteLocalDataBeforeFullSyncUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class DeleteLocalDataBeforeFullSync: DeleteLocalDataBeforeFullSyncUseCase {
    private let itemRepository: ItemRepositoryProtocol
    private let shareRepository: ShareRepositoryProtocol
    private let shareKeyRepository: ShareKeyRepositoryProtocol

    public init(itemRepository: ItemRepositoryProtocol,
                shareRepository: ShareRepositoryProtocol,
                shareKeyRepository: ShareKeyRepositoryProtocol) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.shareKeyRepository = shareKeyRepository
    }

    public func execute() async throws {
        try await itemRepository.deleteAllItemsLocally()
        try await shareRepository.deleteAllSharesLocally()
        try await shareKeyRepository.deleteAllKeysLocally()
    }
}
