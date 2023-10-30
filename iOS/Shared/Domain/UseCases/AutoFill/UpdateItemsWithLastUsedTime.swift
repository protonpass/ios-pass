//
//
// UpdateItemsWithLastUsedTime.swift
// Proton Pass - Created on 27/10/2023.
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
import UseCases

protocol UpdateItemsWithLastUsedTimeUseCase: Sendable {
    func execute() async throws
}

extension UpdateItemsWithLastUsedTimeUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

final class UpdateItemsWithLastUsedTime: UpdateItemsWithLastUsedTimeUseCase {
    private let itemRepository: ItemRepositoryProtocol
    private let indexAllLoginItems: IndexAllLoginItemsUseCase

    init(itemRepository: ItemRepositoryProtocol,
         indexAllLoginItems: IndexAllLoginItemsUseCase) {
        self.indexAllLoginItems = indexAllLoginItems
        self.itemRepository = itemRepository
    }

    func execute() async throws {
        guard let itemsToUpdates = try? await itemRepository.getAllItemLastUsedTime(),
              !itemsToUpdates.isEmpty else {
            return
        }
        try await itemRepository.update(items: itemsToUpdates)
        try await indexAllLoginItems(ignorePreferences: false)
        try await itemRepository.removeAllLastUsedTimeItems()
    }
}
