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

public protocol CanUserShareVaultUseCase: Sendable {
    func execute(for vault: Vault) -> Bool
}

public extension CanUserShareVaultUseCase {
    func callAsFunction(for vault: Vault) -> Bool {
        execute(for: vault)
    }
}

public final class CanUserShareVault: @unchecked Sendable, CanUserShareVaultUseCase {
    private let accessRepository: AccessRepositoryProtocol
    private let getFeatureFlagStatusUseCase: GetFeatureFlagStatusUseCase
    private var isFreeUser = true
    private var sharingFeatureFlagIsOpen = false
    private var isPrimaryVaultRemoved = false

    public init(getFeatureFlagStatusUseCase: GetFeatureFlagStatusUseCase,
                accessRepository: AccessRepositoryProtocol) {
        self.accessRepository = accessRepository
        self.getFeatureFlagStatusUseCase = getFeatureFlagStatusUseCase
        setUp()
    }

    public func execute(for vault: Vault) -> Bool {
        guard sharingFeatureFlagIsOpen,
              vault.isAdmin else {
            return false
        }

        if isFreeUser {
            return isFreeUserAllowedToShare(for: vault)
        } else {
            return isPaidUserAllowedToShare(for: vault)
        }
    }
}

private extension CanUserShareVault {
    func setUp() {
        Task { [weak self] in
            guard let self else {
                return
            }

            async let isFreeUserCheck = try? await accessRepository.getPlan().isFreeUser
            async let isPrimaryRemoved = await getFeatureFlagStatusUseCase(with: FeatureFlagType
                .passRemovePrimaryVault)
            async let featureFlags = await getFeatureFlagStatusUseCase(with: FeatureFlagType.passSharingV1)
            isFreeUser = await isFreeUserCheck ?? true
            sharingFeatureFlagIsOpen = await featureFlags
            isPrimaryVaultRemoved = await isPrimaryRemoved
        }
    }

    func isFreeUserAllowedToShare(for vault: Vault) -> Bool {
        guard vault.totalOverallMembers < 3 else {
            return false
        }
        return finalCheck(for: vault)
    }

    func isPaidUserAllowedToShare(for vault: Vault) -> Bool {
        guard vault.totalOverallMembers < 10 else {
            return false
        }
        return finalCheck(for: vault)
    }

    func finalCheck(for vault: Vault) -> Bool {
        if isPrimaryVaultRemoved {
            vault.canShareVaultWithMorePeople
        } else {
            vault.canShareVaultWithMorePeople && !vault.isPrimary
        }
    }
}
