//
// GetItemContentFromBase64IDs.swift
// Proton Pass - Created on 29/01/2024.
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
import Foundation

public protocol GetItemContentFromBase64IDsUseCase: Sendable {
    func execute(for base64Ids: String) async throws -> ItemContent
}

public extension GetItemContentFromBase64IDsUseCase {
    func callAsFunction(for base64Ids: String) async throws -> ItemContent {
        try await execute(for: base64Ids)
    }
}

public final class GetItemContentFromBase64IDs: GetItemContentFromBase64IDsUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider

    public init(itemRepository: any ItemRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider) {
        self.itemRepository = itemRepository
        self.symmetricKeyProvider = symmetricKeyProvider
    }

    public func execute(for base64Ids: String) async throws -> ItemContent {
        let ids = try IDs.deserializeBase64(base64Ids)
        guard let item = try await itemRepository.getItem(shareId: ids.shareId, itemId: ids.itemId) else {
            throw PassError.itemNotFound(ids)
        }
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        return try item.getItemContent(symmetricKey: symmetricKey)
    }
}
