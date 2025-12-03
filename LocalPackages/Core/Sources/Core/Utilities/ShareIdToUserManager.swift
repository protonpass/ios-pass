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
    // Optimization: Use dictionaries for O(1) lookup instead of linear search
    private var shareIdToUserId = [String: String]()
    private let userIdToModel: [String: UserUiModel]

    public init(users: [UserUiModel]) {
        // Optimization: Pre-build user lookup dictionary
        userIdToModel = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
    }
}

public extension ShareIdToUserManager {
    func index(vaults: [Share], userId: String) {
        for vault in vaults {
            shareIdToUserId[vault.id] = userId
        }
    }

    func getUser(for item: any ItemIdentifiable) throws -> UserUiModel {
        // Optimization: O(1) dictionary lookup instead of O(n) linear search
        guard let userId = shareIdToUserId[item.shareId],
              let user = userIdToModel[userId] else {
            throw PassError.userManager(.noUserFound(shareId: item.shareId, itemId: item.itemId))
        }
        return user
    }
}
