//
// IndexNewLoginItem.swift
// Proton Pass - Created on 03/08/2023.
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

/// Add newly created login item to the credential database
protocol IndexNewLoginItemUseCase: Sendable {
    func execute(for item: SymmetricallyEncryptedItem) async throws
}

extension IndexNewLoginItemUseCase {
    func callAsFunction(for item: SymmetricallyEncryptedItem) async throws {
        try await execute(for: item)
    }
}

final class IndexNewLoginItem: Sendable, IndexNewLoginItemUseCase {
    private let mapLoginItem: MapLoginItemUseCase
    private let manager: CredentialManagerProtocol

    init(mapLoginItem: MapLoginItemUseCase, manager: CredentialManagerProtocol) {
        self.mapLoginItem = mapLoginItem
        self.manager = manager
    }

    func execute(for item: SymmetricallyEncryptedItem) async throws {
        let credentials = try mapLoginItem(for: item)
        try await manager.insert(credentials: credentials)
    }
}
