//
// ReorganizeVaults.swift
// Proton Pass - Created on 16/06/2025.
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

import Client
import Entities

/// Hide/unhide vaults, return `true` if update occured in order to refresh data, `false` otherwise
public protocol ReorganizeVaultsUseCase: Sendable {
    func execute(currentShares: [Share],
                 hiddenShareIds: Set<String>) async throws -> Bool
}

public extension ReorganizeVaultsUseCase {
    func callAsFunction(currentShares: [Share],
                        hiddenShareIds: Set<String>) async throws -> Bool {
        try await execute(currentShares: currentShares, hiddenShareIds: hiddenShareIds)
    }
}

public final class ReorganizeVaults: ReorganizeVaultsUseCase {
    private let userManager: any UserManagerProtocol
    private let shareRepository: any ShareRepositoryProtocol

    public init(userManager: any UserManagerProtocol,
                shareRepository: any ShareRepositoryProtocol) {
        self.userManager = userManager
        self.shareRepository = shareRepository
    }

    public func execute(currentShares: [Share],
                        hiddenShareIds: Set<String>) async throws -> Bool {
        let userId = try await userManager.getActiveUserId()
        var updated = false

        for share in currentShares {
            let shareId = share.shareId
            if share.hidden, !hiddenShareIds.contains(shareId) {
                try await shareRepository.unhideShare(userId: userId, shareId: shareId)
                updated = true
            } else if !share.hidden, hiddenShareIds.contains(shareId) {
                try await shareRepository.hideShare(userId: userId, shareId: shareId)
                updated = true
            }
        }

        return updated
    }
}
