//
// ShareIdToUserManager.swift
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

public protocol ShareIdToUserManagerProtocol {
    func index(vaults: [Vault], userId: String)
    func getUser(for item: any ItemIdentifiable) throws -> UserUiModel
}

/// Cache and keep track of the mapping `ShareID` <-> `User`
/// Used in multi accounts item display context to get the user that owns an item
public final class ShareIdToUserManager: ShareIdToUserManagerProtocol {
    private typealias ShareID = String
    private typealias UserID = String

    private let users: [UserUiModel]
    private var userVaults = Set<UserVault>()

    private var dict = [ShareID: UserID]()

    public init(users: [UserUiModel]) {
        self.users = users
    }
}

public extension ShareIdToUserManager {
    func index(vaults: [Vault], userId: String) {
        for vault in vaults {
            userVaults.insert(.init(userId: userId, vault: vault))
        }
    }

    func getUser(for item: any ItemIdentifiable) throws -> UserUiModel {
        try getCachableUser(for: item).object
    }
}

extension ShareIdToUserManager {
    func getCachableUser(for item: any ItemIdentifiable) throws -> CachableObject<UserUiModel> {
        // Get from cache
        if let userId = dict[item.shareId],
           let user = users.first(where: { $0.id == userId }) {
            return .init(cached: true, object: user)
        }

        // Cache missed, do the math and cache the result
        if let userVault = userVaults.first(where: { $0.vault.shareId == item.shareId }),
           let user = users.first(where: { $0.id == userVault.userId }) {
            dict[item.shareId] = user.id
            return .init(cached: false, object: user)
        }
        throw PassError.userManager(.noUserFound(shareId: item.shareId, itemId: item.itemId))
    }
}
