//
//
// UnpinItem.swift
// Proton Pass - Created on 30/11/2023.
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
import Core
import Entities

public protocol UnpinItemUseCase: Sendable {
    @discardableResult
    func execute(item: any ItemIdentifiable) async throws -> SymmetricallyEncryptedItem
}

public extension UnpinItemUseCase {
    @discardableResult
    func callAsFunction(item: any ItemIdentifiable) async throws -> SymmetricallyEncryptedItem {
        try await execute(item: item)
    }
}

public final class UnpinItem: UnpinItemUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let logger: Logger

    public init(itemRepository: any ItemRepositoryProtocol,
                logManager: any LogManagerProtocol) {
        self.itemRepository = itemRepository
        logger = .init(manager: logManager)
    }

    public func execute(item: any ItemIdentifiable) async throws -> SymmetricallyEncryptedItem {
        logger.trace("Pinning item \(item.debugDescription)")
        return try await itemRepository.unpinItem(item: item)
    }
}
