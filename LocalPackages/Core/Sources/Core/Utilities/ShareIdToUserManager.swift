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
    let shareId: String
}

public protocol ShareIdToUserManagerProtocol {
    func index(vaults: [Share], userId: String)
    func getUser(for item: any ItemIdentifiable) throws -> UserUiModel
}

/// Cache and keep track of the mapping `ShareID` <-> `User`
/// Used in multi accounts item display context to get the user that owns an item
public final class ShareIdToUserManager: ShareIdToUserManagerProtocol {
    private let users: [UserUiModel]
    private var userVaults = Set<UserVault>()

    public init(users: [UserUiModel]) {
        self.users = users
    }
}

public extension ShareIdToUserManager {
    func index(vaults: [Share], userId: String) {
        for vault in vaults {
            userVaults.insert(.init(userId: userId, shareId: vault.id))
        }
    }

    func getUser(for item: any ItemIdentifiable) throws -> UserUiModel {
        guard let userId = userVaults.first(where: { $0.shareId == item.shareId })?.userId,
              let user = users.first(where: { $0.id == userId }) else {
            throw PassError.userManager(.noUserFound(shareId: item.shareId, itemId: item.itemId))
        }
        return user
    }
}
