//
//
// GetActiveLoginItems.swift
// Proton Pass - Created on 30/01/2024.
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

public protocol GetActiveLoginItemsUseCase: Sendable {
    func execute(userId: String) async throws -> [ItemContent]
}

public extension GetActiveLoginItemsUseCase {
    func callAsFunction(userId: String) async throws -> [ItemContent] {
        try await execute(userId: userId)
    }
}

public final class GetActiveLoginItems: GetActiveLoginItemsUseCase {
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let repository: any ItemRepositoryProtocol

    public init(symmetricKeyProvider: any SymmetricKeyProvider,
                repository: any ItemRepositoryProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        self.repository = repository
    }

    public func execute(userId: String) async throws -> [ItemContent] {
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let encryptedItems = try await repository.getActiveLogInItems(userId: userId)
        return try encryptedItems.map { try $0.getItemContent(symmetricKey: symmetricKey) }
    }
}
