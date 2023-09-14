//
//
// MoveItemsBetweenVaults.swift
// Proton Pass - Created on 13/09/2023.
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

enum MovingContext {
    case item(ItemIdentifiable, newShareId: String)
    case vault(String, newShareId: String)
}

protocol MoveItemsBetweenVaultsUseCase: Sendable {
    func execute(movingContext: MovingContext) async throws
}

extension MoveItemsBetweenVaultsUseCase {
    func callAsFunction(movingContext: MovingContext) async throws {
        try await execute(movingContext: movingContext)
    }
}

final class MoveItemsBetweenVaults: MoveItemsBetweenVaultsUseCase {
    private let repository: ItemRepositoryProtocol

    init(repository: ItemRepositoryProtocol) {
        self.repository = repository
    }

    func execute(movingContext: MovingContext) async throws {
        switch movingContext {
        case let .item(itemToMove, newShareId):
            try await repository.move(item: itemToMove, toShareId: newShareId)
        case let .vault(currentSharedId, newShareId):
            try await repository.move(currentShareId: currentSharedId, toShareId: newShareId)
        }
    }
}
