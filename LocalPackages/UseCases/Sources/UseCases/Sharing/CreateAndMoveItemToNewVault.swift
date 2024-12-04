//
// CreateAndMoveItemToNewVault.swift
// Proton Pass - Created on 10/10/2023.
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
import Entities

// sourcery: AutoMockable
public protocol CreateAndMoveItemToNewVaultUseCase: Sendable {
    func execute(userId: String, vault: VaultContent, itemContent: ItemContent) async throws -> Share
}

public extension CreateAndMoveItemToNewVaultUseCase {
    func callAsFunction(userId: String, vault: VaultContent, itemContent: ItemContent) async throws -> Share {
        try await execute(userId: userId, vault: vault, itemContent: itemContent)
    }
}

public final class CreateAndMoveItemToNewVault: CreateAndMoveItemToNewVaultUseCase {
    private let createVault: any CreateVaultUseCase
    private let moveItemsBetweenVaults: any MoveItemsBetweenVaultsUseCase
    private let appContentManager: any AppContentManagerProtocol

    public init(createVault: any CreateVaultUseCase,
                moveItemsBetweenVaults: any MoveItemsBetweenVaultsUseCase,
                appContentManager: any AppContentManagerProtocol) {
        self.createVault = createVault
        self.moveItemsBetweenVaults = moveItemsBetweenVaults
        self.appContentManager = appContentManager
    }

    public func execute(userId: String, vault: VaultContent, itemContent: ItemContent) async throws -> Share {
        do {
            if let vault = try await createVault(userId: userId, with: vault) {
                try await moveItemsBetweenVaults(context: .singleItem(itemContent),
                                                 to: vault.shareId)
                appContentManager.refresh(userId: userId)
                return vault
            } else {
                throw PassError.sharing(.failedToCreateNewVault)
            }
        } catch {
            throw PassError.sharing(.failedToCreateNewVault)
        }
    }
}
