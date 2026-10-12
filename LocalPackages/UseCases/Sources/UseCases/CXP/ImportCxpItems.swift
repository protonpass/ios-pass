//
// ImportCxpItems.swift
// Proton Pass - Created on 02/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

public protocol ImportCxpItemsUseCase: Sendable {
    func callAsFunction(userId: String,
                        result: CxpImportResult,
                        defaultVaultContent: VaultContent,
                        onProgress: (@Sendable (_ importedCount: Int) async -> Void)?) async throws
}

public struct ImportCxpItems: ImportCxpItemsUseCase {
    private let shareRepository: any ShareRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let checkVaultCreationAllowance: any CheckVaultCreationAllowanceUseCase

    public init(shareRepository: any ShareRepositoryProtocol,
                itemRepository: any ItemRepositoryProtocol,
                checkVaultCreationAllowance: any CheckVaultCreationAllowanceUseCase) {
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.checkVaultCreationAllowance = checkVaultCreationAllowance
    }

    public func callAsFunction(userId: String,
                               result: CxpImportResult,
                               defaultVaultContent: VaultContent,
                               onProgress: (@Sendable (_ importedCount: Int) async -> Void)?) async throws {
        let importableVaults = result.vaults.filter { !$0.items.isEmpty }
        switch try await checkVaultCreationAllowance(userId: userId,
                                                     newVaultCount: importableVaults.count) {
        case .allowed:
            break

        case .vaultLimitReached:
            throw PassError.importer(.vaultLimitReached)

        case .notAllowedByOrganization:
            throw PassError.importer(.vaultCreationNotAllowed)
        }

        var importedCount = 0
        var unnamedVaultCount = 0
        for importableVault in importableVaults {
            var vault = importableVault.vault ?? defaultVaultContent
            if importableVault.vault == nil {
                unnamedVaultCount += 1
                if unnamedVaultCount > 1 {
                    vault.name += " (\(unnamedVaultCount))"
                }
            }
            let share = try await shareRepository.createVault(userId: userId, vault: vault)
            let offset = importedCount
            try await itemRepository.importItems(userId: userId,
                                                 shareId: share.shareId,
                                                 contents: importableVault.items,
                                                 onProgress: { await onProgress?(offset + $0) })
            importedCount += importableVault.items.count
        }
    }
}
