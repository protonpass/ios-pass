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
    func execute(vault: VaultProtobuf, itemContent: ItemContent) async throws -> Vault
}

public extension CreateAndMoveItemToNewVaultUseCase {
    func callAsFunction(vault: VaultProtobuf, itemContent: ItemContent) async throws -> Vault {
        try await execute(vault: vault, itemContent: itemContent)
    }
}

public final class CreateAndMoveItemToNewVault: CreateAndMoveItemToNewVaultUseCase {
    private let createVault: CreateVaultUseCase
    private let moveItemsBetweenVaults: MoveItemsBetweenVaultsUseCase
    private let vaultsManager: VaultsManagerProtocol

    public init(createVault: CreateVaultUseCase,
                moveItemsBetweenVaults: MoveItemsBetweenVaultsUseCase,
                vaultsManager: VaultsManagerProtocol) {
        self.createVault = createVault
        self.moveItemsBetweenVaults = moveItemsBetweenVaults
        self.vaultsManager = vaultsManager
    }

    public func execute(vault: VaultProtobuf, itemContent: ItemContent) async throws -> Vault {
        do {
            if let vault = try await createVault(with: vault) {
                try await moveItemsBetweenVaults(movingContext: .item(itemContent,
                                                                      newShareId: vault.shareId))
                vaultsManager.refresh()
                return vault
            } else {
                throw PassError.sharing(.failedToCreateNewVault)
            }
        } catch {
            throw PassError.sharing(.failedToCreateNewVault)
        }
    }
}
