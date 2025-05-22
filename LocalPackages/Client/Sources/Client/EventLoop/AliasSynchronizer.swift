//
// AliasSynchronizer.swift
// Proton Pass - Created on 21/05/2025.
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
import Foundation

public protocol AliasSynchronizerProtocol: Sendable {
    /// Return `true` if there were newly synced aliases, `false` otherwise
    func sync(userId: String) async throws -> Bool
}

public actor AliasSynchronizer: AliasSynchronizerProtocol {
    private let accessRepository: any AccessRepositoryProtocol
    private let aliasRepository: any AliasRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol

    public init(accessRepository: any AccessRepositoryProtocol,
                aliasRepository: any AliasRepositoryProtocol,
                itemRepository: any ItemRepositoryProtocol) {
        self.accessRepository = accessRepository
        self.aliasRepository = aliasRepository
        self.itemRepository = itemRepository
    }

    public func sync(userId: String) async throws -> Bool {
        let settings = try await accessRepository.getAccess(userId: userId).access.userData
        guard settings.aliasSyncEnabled,
              settings.pendingAliasToSync > 0,
              let shareId = settings.defaultShareID else {
            return false
        }

        var hasNewSyncedAliases = false
        var sinceLastToken: String?

        while true {
            let paginatedAlias = try await aliasRepository.getPendingAliasesToSync(userId: userId,
                                                                                   since: sinceLastToken)

            if paginatedAlias.aliases.isEmpty {
                break
            }

            let itemsContent = Dictionary(uniqueKeysWithValues: paginatedAlias.aliases.map { alias in
                (alias.pendingAliasID, ItemContentProtobuf(name: alias.aliasEmail,
                                                           note: "",
                                                           itemUuid: UUID().uuidString,
                                                           data: .alias,
                                                           customFields: []))
            })

            _ = try await itemRepository.createPendingAliasesItem(userId: userId,
                                                                  shareId: shareId,
                                                                  itemsContent: itemsContent)
            hasNewSyncedAliases = true

            // Move to the next page
            sinceLastToken = paginatedAlias.lastToken
        }
        return hasNewSyncedAliases
    }
}
