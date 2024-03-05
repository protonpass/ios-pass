//
// GetItemsForPasskeyCreation.swift
// Proton Pass - Created on 27/02/2024.
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

import Client
import Entities
import Foundation

protocol GetItemsForPasskeyCreationUseCase: Sendable {
    func execute() async throws -> ([SearchableItem], [ItemUiModel])
}

extension GetItemsForPasskeyCreationUseCase {
    func callAsFunction() async throws -> ([SearchableItem], [ItemUiModel]) {
        try await execute()
    }
}

final class GetItemsForPasskeyCreation: GetItemsForPasskeyCreationUseCase {
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let shareRepository: any ShareRepositoryProtocol
    private let itemRepositiry: any ItemRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol

    init(symmetricKeyProvider: any SymmetricKeyProvider,
         shareRepository: any ShareRepositoryProtocol,
         itemRepositiry: any ItemRepositoryProtocol,
         accessRepository: any AccessRepositoryProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        self.shareRepository = shareRepository
        self.itemRepositiry = itemRepositiry
        self.accessRepository = accessRepository
    }

    func execute() async throws -> ([SearchableItem], [ItemUiModel]) {
        async let getSymmetricKey = symmetricKeyProvider.getSymmetricKey()
        async let getVaults = shareRepository.getVaults()
        async let getActiveLogInItems = itemRepositiry.getActiveLogInItems()
        async let getPlan = accessRepository.getPlan()

        let symmetricKey = try await getSymmetricKey
        let vaults = try await getVaults
        let items = try await getActiveLogInItems
        let plan = try await getPlan

        var searchableItems = [SearchableItem]()
        var includedItems = [SymmetricallyEncryptedItem]()

        for item in items {
            guard let vault = vaults.first(where: { $0.shareId == item.shareId }),
                  shouldTakeVaultIntoAccount(vault, allVaults: vaults, plan: plan) else {
                continue
            }
            includedItems.append(item)
            try searchableItems.append(.init(from: item,
                                             symmetricKey: symmetricKey,
                                             allVaults: vaults))
        }

        let uiModels = try await includedItems.parallelMap { try $0.toItemUiModel(symmetricKey) }
        assert(searchableItems.count == includedItems.count, "Should have the same amount of items")
        return (searchableItems, uiModels)
    }
}

private extension GetItemsForPasskeyCreation {
    func shouldTakeVaultIntoAccount(_ vault: Vault, allVaults: [Vault], plan: Plan) -> Bool {
        switch plan.planType {
        case .free:
            allVaults.twoOldestVaults.isOneOf(shareId: vault.shareId)
        default:
            true
        }
    }
}
