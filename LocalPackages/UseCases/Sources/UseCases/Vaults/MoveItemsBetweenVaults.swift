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

// sourcery: AutoMockable
public protocol MoveItemsBetweenVaultsUseCase: Sendable {
    func execute(context: MovingContext, to shareId: ShareID) async throws
}

public extension MoveItemsBetweenVaultsUseCase {
    func callAsFunction(context: MovingContext, to shareId: ShareID) async throws {
        try await execute(context: context, to: shareId)
    }
}

public final class MoveItemsBetweenVaults: MoveItemsBetweenVaultsUseCase {
    private let repository: any ItemRepositoryProtocol

    public init(repository: any ItemRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(context: MovingContext, to shareId: ShareID) async throws {
        switch context {
        case let .singleItem(item):
            try await repository.move(items: [item], toShareId: shareId)
        case let .allItems(fromVault):
            try await repository.move(currentShareId: fromVault.shareId, toShareId: shareId)
        case let .selectedItems(items):
            try await repository.move(items: items, toShareId: shareId)
        }
    }
}
