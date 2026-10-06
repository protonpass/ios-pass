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
    /// Throws `PassError.importer(.vaultLimitReached)` or `.vaultCreationNotAllowed`
    /// before importing anything when the needed vaults can't all be created
    func callAsFunction(userId: String,
                        result: CxpImportResult,
                        defaultVaultName: String,
                        onProgress: (@Sendable (_ importedCount: Int) async -> Void)?) async throws
}

public struct ImportCxpItems: ImportCxpItemsUseCase {
    private let userManager: any UserManagerProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let organizationRepository: any OrganizationRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let checkVaultCreationAllowance: any CheckVaultCreationAllowanceUseCase

    public init(userManager: any UserManagerProtocol,
                accessRepository: any AccessRepositoryProtocol,
                organizationRepository: any OrganizationRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                itemRepository: any ItemRepositoryProtocol,
                checkVaultCreationAllowance: any CheckVaultCreationAllowanceUseCase) {
        self.userManager = userManager
        self.accessRepository = accessRepository
        self.organizationRepository = organizationRepository
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.checkVaultCreationAllowance = checkVaultCreationAllowance
    }

    public func callAsFunction(userId: String,
                               result: CxpImportResult,
                               defaultVaultName: String,
                               onProgress: (@Sendable (_ importedCount: Int) async -> Void)?) async throws {
        let importedVaults = result.vaults.filter { !$0.items.isEmpty }
        try await checkCanCreate(newVaultCount: importedVaults.count, userId: userId)

        var importedCount = 0
        for importedVault in importedVaults {
            let vault = importedVault.vault ?? .init(name: defaultVaultName,
                                                     description: "",
                                                     color: .color1,
                                                     icon: .icon1)
            let share = try await shareRepository.createVault(userId: userId, vault: vault)
            let offset = importedCount
            try await itemRepository.importItems(userId: userId,
                                                 shareId: share.shareId,
                                                 contents: importedVault.items,
                                                 onProgress: { await onProgress?(offset + $0) })
            importedCount += importedVault.items.count
        }
    }
}

private extension ImportCxpItems {
    func checkCanCreate(newVaultCount: Int, userId: String) async throws {
        let vaultCount = try await shareRepository.getShares(userId: userId)
            .count(where: \.share.isVaultRepresentation)
        let plan = try await accessRepository.getPlan(userId: userId)
        if let vaultLimit = plan.vaultLimit, vaultCount + newVaultCount > vaultLimit {
            throw PassError.importer(.vaultLimitReached)
        }

        guard plan.isBusinessUser else { return }
        let userData = try await userManager.getUserData(userId)
        let organization = try await organizationRepository.getOrganization(userId: userId)
        let allowed = (0..<newVaultCount).allSatisfy {
            checkVaultCreationAllowance(userData: userData,
                                        organization: organization,
                                        vaultCount: vaultCount + $0)
        }
        if !allowed {
            throw PassError.importer(.vaultCreationNotAllowed)
        }
    }
}
