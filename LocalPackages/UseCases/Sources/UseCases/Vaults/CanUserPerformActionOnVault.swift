//
//
// CanUserPerformActionOnVault.swift
// Proton Pass - Created on 16/10/2023.
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

public protocol CanUserPerformActionOnVaultUseCase: Sendable {
    func execute(for vault: Vault) -> Bool
}

public extension CanUserPerformActionOnVaultUseCase {
    func callAsFunction(for vault: Vault) -> Bool {
        execute(for: vault)
    }
}

public final class CanUserPerformActionOnVault: @unchecked Sendable, CanUserPerformActionOnVaultUseCase {
    private let accessRepository: any AccessRepositoryProtocol
    private let vaultsManager: any VaultsManagerProtocol
    private var isFreeUser = true

    public init(accessRepository: any AccessRepositoryProtocol,
                vaultsManager: any VaultsManagerProtocol) {
        self.accessRepository = accessRepository
        self.vaultsManager = vaultsManager
        setUp()
    }

    public func execute(for vault: Vault) -> Bool {
        if isFreeUser, !vaultsManager.currentVaults.value.twoOldestVaults.isOneOf(shareId: vault.shareId) {
            return false
        }
        return vault.canEdit
    }
}

private extension CanUserPerformActionOnVault {
    func setUp() {
        Task { [weak self] in
            guard let self, let userPlan = try? await accessRepository.getPlan(userId: nil) else {
                return
            }

            isFreeUser = userPlan.isFreeUser
        }
    }
}
