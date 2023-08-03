//
// IndexLoginItem.swift
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
import Core

/// Add newly created/updated  login item to the credential database
protocol IndexLoginItemUseCase: Sendable {
    func execute(for item: SymmetricallyEncryptedItem) async throws
}

extension IndexLoginItemUseCase {
    func callAsFunction(for item: SymmetricallyEncryptedItem) async throws {
        try await execute(for: item)
    }
}

final class IndexLoginItem: Sendable, IndexLoginItemUseCase {
    private let mapLoginItem: MapLoginItemUseCase
    private let credentialManager: CredentialManagerProtocol
    private let logger: Logger

    init(mapLoginItem: MapLoginItemUseCase,
         credentialManager: CredentialManagerProtocol,
         logManager: LogManagerProtocol) {
        self.mapLoginItem = mapLoginItem
        self.credentialManager = credentialManager
        logger = .init(manager: logManager)
    }

    func execute(for item: SymmetricallyEncryptedItem) async throws {
        logger.trace("Indexing \(item.debugInformation)")
        let credentials = try mapLoginItem(for: item)
        try await credentialManager.insert(credentials: credentials)
        logger.trace("Indexed \(item.debugInformation)")
    }
}
