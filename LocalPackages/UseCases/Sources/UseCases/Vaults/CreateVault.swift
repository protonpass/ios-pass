//
//
// CreateVault.swift
// Proton Pass - Created on 14/09/2023.
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
import Entities

// sourcery: AutoMockable
public protocol CreateVaultUseCase: Sendable {
    @discardableResult
    func execute(userId: String, with vault: VaultContent) async throws -> Share?
}

public extension CreateVaultUseCase {
    @discardableResult
    func callAsFunction(userId: String, with vault: VaultContent) async throws -> Share? {
        try await execute(userId: userId, with: vault)
    }
}

public final class CreateVault: CreateVaultUseCase {
    private let appContentManager: any AppContentManagerProtocol
    private let repository: any ShareRepositoryProtocol

    public init(appContentManager: any AppContentManagerProtocol,
                repository: any ShareRepositoryProtocol) {
        self.appContentManager = appContentManager
        self.repository = repository
    }

    public func execute(userId: String, with vault: VaultContent) async throws -> Share? {
        let share = try await repository.createVault(userId: userId, vault: vault)
        try await appContentManager.refresh(userId: userId)

        return try await repository.getDecryptedShare(shareId: share.shareID)
    }
}
