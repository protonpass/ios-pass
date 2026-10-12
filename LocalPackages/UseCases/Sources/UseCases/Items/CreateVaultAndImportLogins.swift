//
// CreateVaultAndImportLogins.swift
// Proton Pass - Created on 06/02/2025.
// Copyright (c) 2025 Proton Technologies AG
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

public protocol CreateVaultAndImportLoginsUseCase: Sendable {
    func callAsFunction(userId: String,
                        logins: [CsvLogin],
                        vaultContent: VaultContent) async throws
}

public struct CreateVaultAndImportLogins: CreateVaultAndImportLoginsUseCase {
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
                               logins: [CsvLogin],
                               vaultContent: VaultContent) async throws {
        switch try await checkVaultCreationAllowance(userId: userId, newVaultCount: 1) {
        case .allowed:
            break

        case .vaultLimitReached:
            throw PassError.importer(.vaultLimitReached)

        case .notAllowedByOrganization:
            throw PassError.importer(.vaultCreationNotAllowed)
        }

        let share = try await shareRepository.createVault(userId: userId,
                                                          vault: vaultContent)
        try await itemRepository.importLogins(userId: userId,
                                              shareId: share.shareId,
                                              logins: logins)
    }
}
