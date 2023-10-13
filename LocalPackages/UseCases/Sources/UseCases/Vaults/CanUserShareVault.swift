//
//  
// CanUserShareVault.swift
// Proton Pass - Created on 13/10/2023.
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

protocol CanUserShareVaultUseCase: Sendable {
   // func execute() async throws
}

extension CanUserShareVaultUseCase {
    func callAsFunction() {
      // execute()
    }
}

final class CanUserShareVault: CanUserShareVaultUseCase {
    private let planRepository: PassPlanRepositoryProtocol
    private let featureFlagsRepository: FeatureFlagsRepositoryProtocol
    // TODO add the sharing feature flag check
    init(private let featureFlagsRepository: FeatureFlagsRepositoryProtocol
        planRepository: PassPlanRepositoryProtocol) {
        self.planRepository = planRepository
    }
    
    func execute(for vault: Vault) async throws -> Bool {
        guard vault.isAdmin else {
            return false
        }
        if try await planRepository.getPlan().isFreeUser {
            isFreeUserAllowedToShare(for: vault)
        } else {
            isPaidUserAllowedToShare(for: vault)
        }
    }
}

private extension CanUserShareVault {
    func isFreeUserAllowedToShare(for vault: Vault) -> Bool {
        guard vault.totalOverallMembers < 3 else {
            return false
        }
        return true
    }
    
    func isPaidUserAllowedToShare(for vault: Vault) -> Bool {
        guard vault.totalOverallMembers < 10 else {
            return false
        }
        return true
    }
}
