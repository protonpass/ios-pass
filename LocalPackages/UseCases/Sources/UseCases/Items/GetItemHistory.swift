//
//
// GetItemHistory.swift
// Proton Pass - Created on 09/01/2024.
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

import Client
import Entities

public protocol GetItemHistoryUseCase: Sendable {
    func execute(shareId: String, itemId: String, lastToken: String?) async throws -> Paginated<ItemContent>
}

public extension GetItemHistoryUseCase {
    func callAsFunction(shareId: String,
                        itemId: String,
                        lastToken: String?) async throws -> Paginated<ItemContent> {
        try await execute(shareId: shareId, itemId: itemId, lastToken: lastToken)
    }
}

public final class GetItemHistory: GetItemHistoryUseCase {
    private let itemRepository: any ItemRepositoryProtocol

    public init(itemRepository: any ItemRepositoryProtocol) {
        self.itemRepository = itemRepository
    }

    public func execute(shareId: String,
                        itemId: String,
                        lastToken: String?) async throws -> Paginated<ItemContent> {
        try await itemRepository.getItemRevisions(shareId: shareId,
                                                  itemId: itemId,
                                                  lastToken: lastToken)
    }
}
