//
//
// GetUserShareStatus.swift
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
import Entities

public protocol GetUserShareStatusUseCase: Sendable {
    func execute(for vault: Vault) -> UserShareStatus
}

public extension GetUserShareStatusUseCase {
    func callAsFunction(for vault: Vault) -> UserShareStatus {
        execute(for: vault)
    }
}

public enum UserShareStatus {
    case canShare
    case cantShare
    case upsell
}

public final class GetUserShareStatus: @unchecked Sendable, GetUserShareStatusUseCase {
    private let accessRepository: AccessRepositoryProtocol
    private let getFeatureFlagStatusUseCase: GetFeatureFlagStatusUseCase
    private var isFreeUser = true
    private var sharingFeatureFlagIsOpen = false

    public init(getFeatureFlagStatusUseCase: GetFeatureFlagStatusUseCase,
                accessRepository: AccessRepositoryProtocol) {
        self.accessRepository = accessRepository
        self.getFeatureFlagStatusUseCase = getFeatureFlagStatusUseCase
        setUp()
    }

    public func execute(for vault: Vault) -> UserShareStatus {
        guard sharingFeatureFlagIsOpen,
              vault.isAdmin || vault.isOwner else {
            return .cantShare
        }

        if isFreeUser {
            return isFreeUserAllowedToShare(for: vault)
        } else {
            return isPaidUserAllowedToShare(for: vault)
        }
    }
}

private extension GetUserShareStatus {
    func setUp() {
        Task { [weak self] in
            guard let self else {
                return
            }

            async let isFreeUserCheck = try? await accessRepository.getPlan().isFreeUser
            async let featureFlags = await getFeatureFlagStatusUseCase(with: FeatureFlagType.passSharingV1)
            isFreeUser = await isFreeUserCheck ?? true
            sharingFeatureFlagIsOpen = await featureFlags
        }
    }

    func isFreeUserAllowedToShare(for vault: Vault) -> UserShareStatus {
        guard vault.totalOverallMembers < 3 else {
            return .upsell
        }

        return finalCheck(for: vault) ? .canShare : .upsell
    }

    func isPaidUserAllowedToShare(for vault: Vault) -> UserShareStatus {
        guard vault.totalOverallMembers < 10 else {
            return .cantShare
        }
        return finalCheck(for: vault) ? .canShare : .cantShare
    }

    func finalCheck(for vault: Vault) -> Bool {
        vault.canShareVaultWithMorePeople
    }
}
