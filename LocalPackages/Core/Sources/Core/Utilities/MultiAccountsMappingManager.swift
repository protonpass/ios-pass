//
// MultiAccountsMappingManager.swift
// Proton Pass - Created on 10/09/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities

private struct UserVault: Sendable, Hashable {
    let userId: String
    let vault: Vault
}

/// Cache and keep track of the mapping `ShareID` <-> `User` & `ShareID` <-> `VaultID`
/// Used in multi accounts item display context:
/// - Get the corresponding `VaultID` of item's `ShareID` to find out the same items across shared vaults
/// - Get the `User` that owns an item
public final class MultiAccountsMappingManager {
    private typealias ShareID = String
    private typealias VaultID = String
    private typealias UserID = String

    private var users = Set<PassUser>()
    private var userVaults = Set<UserVault>()

    private var shareToVault = [ShareID: VaultID]()
    private var shareToUser = [ShareID: UserID]()

    public init() {}
}

public extension MultiAccountsMappingManager {
    func add(_ users: [PassUser]) {
        for user in users {
            self.users.insert(user)
        }
    }

    func add(_ vaults: [Vault], userId: String) {
        for vault in vaults {
            userVaults.insert(.init(userId: userId, vault: vault))
        }
    }

    func getVaultId(for shareId: String) throws -> CachableObject<String> {
        if let vaultId = shareToVault[shareId] {
            return .init(cached: true, object: vaultId)
        }
        if let vault = userVaults.map(\.vault).first(where: { $0.shareId == shareId }) {
            shareToVault[shareId] = vault.id
            return .init(cached: false, object: vault.id)
        }
        throw PassError.vault(.vaultNotFound(shareId: shareId))
    }

    func getUser(for item: any ItemIdentifiable) throws -> CachableObject<PassUser> {
        // Get from cache
        if let userId = shareToUser[item.shareId],
           let user = users.first(where: { $0.id == userId }) {
            return .init(cached: true, object: user)
        }

        // Cache missed, do the math and cache the result
        if let userVault = userVaults.first(where: { $0.vault.shareId == item.shareId }),
           let user = users.first(where: { $0.id == userVault.userId }) {
            shareToUser[item.shareId] = user.id
            return .init(cached: false, object: user)
        }
        throw PassError.userManager(.noUserFound(shareId: item.shareId, itemId: item.itemId))
    }
}
