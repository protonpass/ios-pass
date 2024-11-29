//
// GetSpotlightVaults.swift
// Proton Pass - Created on 01/02/2024.
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
//

import Client
import Entities

public protocol GetSpotlightVaultsUseCase: Sendable {
    func execute() async throws -> [Share]
}

public extension GetSpotlightVaultsUseCase {
    func callAsFunction() async throws -> [Share] {
        try await execute()
    }
}

public final class GetSpotlightVaults: GetSpotlightVaultsUseCase {
    private let userManager: any UserManagerProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let localSpotlightVaultDatasource: any LocalSpotlightVaultDatasourceProtocol

    public init(userManager: any UserManagerProtocol,
                shareRepository: any ShareRepositoryProtocol,
                localSpotlightVaultDatasource: any LocalSpotlightVaultDatasourceProtocol) {
        self.userManager = userManager
        self.shareRepository = shareRepository
        self.localSpotlightVaultDatasource = localSpotlightVaultDatasource
    }

    public func execute() async throws -> [Share] {
        let userId = try await userManager.getActiveUserId()
        let selectedIds = try await localSpotlightVaultDatasource.getIds(for: userId)
        let vaults = try await shareRepository.getVaults(userId: userId)
        return vaults.filter { vault in
            selectedIds.contains(vault.id)
        }
    }
}
