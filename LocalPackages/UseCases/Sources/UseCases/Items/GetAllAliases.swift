//
//
// GetAllAliases.swift
// Proton Pass - Created on 17/04/2024.
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

public protocol GetAllAliasesUseCase: Sendable {
    func execute() async throws -> [ItemContent]
}

public extension GetAllAliasesUseCase {
    func callAsFunction() async throws -> [ItemContent] {
        try await execute()
    }
}

public final class GetAllAliases: GetAllAliasesUseCase {
    private let itemRepository: any ItemRepositoryProtocol

    public init(itemRepository: any ItemRepositoryProtocol) {
        self.itemRepository = itemRepository
    }

    public func execute() async throws -> [ItemContent] {
        try await itemRepository.getAllItemContents()
            .filter { $0.contentData == .alias && $0.item.itemState == .active }
    }
}
