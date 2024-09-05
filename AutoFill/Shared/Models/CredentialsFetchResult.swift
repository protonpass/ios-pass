//
// CredentialsFetchResult.swift
// Proton Pass - Created on 07/07/2023.
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

import Client
import Entities
import Foundation

struct VaultIdentifiableObject<T: Sendable & Hashable & ItemIdentifiable>: Sendable, Hashable {
    let vaultId: String
    let object: T
}

extension VaultIdentifiableObject: ItemIdentifiable {
    var shareId: String {
        object.shareId
    }

    var itemId: String {
        object.itemId
    }
}

private extension VaultIdentifiableObject {
    init(vaults: [Vault], object: T) throws {
        guard let vault = vaults.first(where: { $0.shareId == object.shareId }) else {
            throw PassError.vault(.vaultNotFound(shareId: object.shareId))
        }
        vaultId = vault.id
        self.object = object
    }
}

struct CredentialsFetchResult: Equatable, Sendable {
    let userId: String
    let vaults: [Vault]
    let searchableItems: [VaultIdentifiableObject<SearchableItem>]
    let matchedItems: [VaultIdentifiableObject<ItemUiModel>]
    let notMatchedItems: [VaultIdentifiableObject<ItemUiModel>]

    var isEmpty: Bool {
        searchableItems.isEmpty && matchedItems.isEmpty && notMatchedItems.isEmpty
    }

    init(userId: String,
         vaults: [Vault],
         searchableItems: [SearchableItem],
         matchedItems: [ItemUiModel],
         notMatchedItems: [ItemUiModel]) throws {
        self.userId = userId
        self.vaults = vaults
        self.searchableItems = try searchableItems.map { try .init(vaults: vaults, object: $0) }
        self.matchedItems = try matchedItems.map { try .init(vaults: vaults, object: $0) }
        self.notMatchedItems = try notMatchedItems.map { try .init(vaults: vaults, object: $0) }
    }
}
