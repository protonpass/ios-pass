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
@preconcurrency import CryptoKit
import Entities
import Foundation

protocol GetItemsForPasskeyCreationUseCase: Sendable {
    func execute(userId: String, _ request: PasskeyCredentialRequest) async throws
        -> CredentialsForPasskeyCreation
}

extension GetItemsForPasskeyCreationUseCase {
    func callAsFunction(userId: String,
                        _ request: PasskeyCredentialRequest) async throws -> CredentialsForPasskeyCreation {
        try await execute(userId: userId, request)
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

    func execute(userId: String,
                 _ request: PasskeyCredentialRequest) async throws -> CredentialsForPasskeyCreation {
        async let getSymmetricKey = symmetricKeyProvider.getSymmetricKey()
        async let getVaults = shareRepository.getVaults(userId: userId)
        async let getActiveLogInItems = itemRepositiry.getActiveLogInItems(userId: userId)
        async let getPlan = accessRepository.getPlan(userId: userId)

        let symmetricKey = try await getSymmetricKey
        let vaults = try await getVaults
        let items = try await getActiveLogInItems
        let plan = try await getPlan

        var searchableItems = [SearchableItem]()
        var includedItems = [SymmetricallyEncryptedItem]()

        let allowedVaults = vaults.autofillAllowedVaults
        for item in items {
            guard let vault = vaults.first(where: { $0.shareId == item.shareId }),
                  shouldTakeVaultIntoAccount(vault, allowedVaults: allowedVaults, plan: plan) else {
                continue
            }
            includedItems.append(item)
            try searchableItems.append(.init(from: item,
                                             symmetricKey: symmetricKey,
                                             allVaults: vaults))
        }

        let uiModels = try await includedItems
            .parallelMap { try $0.getItemContent(symmetricKey: symmetricKey) }
            .sorted { lhs, rhs in
                let lhsMatched = lhs
                    .loginIdentifiableFields
                    .contains(where: {
                        $0.contains(request.userName) ||
                            $0.contains(request.serviceIdentifier.identifier) ||
                            $0.contains(request.relyingPartyIdentifier)
                    })
                let rhsMatched = rhs
                    .loginIdentifiableFields
                    .contains(where: {
                        $0.contains(request.userName) ||
                            $0.contains(request.serviceIdentifier.identifier) ||
                            $0.contains(request.relyingPartyIdentifier)
                    })
                switch (lhsMatched, rhsMatched) {
                case (true, false):
                    // Left matched, right NOT matched
                    // => Left is above right
                    return true
                case (false, true):
                    // Left NOT matched, right matched
                    // => Left is below right
                    return false
                case (true, true):
                    // Both are matched
                    // => Base on lastUseTime if any and default to modifyTime
                    let lhsTime = lhs.item.lastUseTime ?? lhs.item.modifyTime
                    let rhsTime = rhs.item.lastUseTime ?? rhs.item.modifyTime
                    return lhsTime > rhsTime
                case (false, false):
                    // Nothing matched
                    // => Base on modifyTime
                    return lhs.item.modifyTime > rhs.item.modifyTime
                }
            }
            .map(\.toItemUiModel)
        assert(searchableItems.count == includedItems.count, "Should have the same amount of items")
        return .init(userId: userId,
                     vaults: vaults,
                     searchableItems: searchableItems,
                     items: uiModels)
    }
}

private extension GetItemsForPasskeyCreation {
    func shouldTakeVaultIntoAccount(_ vault: Vault, allowedVaults: [Vault], plan: Plan) -> Bool {
        switch plan.planType {
        case .free:
            allowedVaults.contains(where: { $0.shareId == vault.shareId })
        default:
            true
        }
    }
}
