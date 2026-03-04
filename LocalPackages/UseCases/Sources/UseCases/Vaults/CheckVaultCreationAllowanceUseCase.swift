//
// CheckVaultCreationAllowanceUseCase.swift
// Proton Pass - Created on 04/03/2026.
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
import ProtonCoreLogin

public protocol CheckVaultCreationAllowanceUseCase: Sendable {
    func execute(userData: UserData?,
                 organization: Entities.Organization?,
                 vaultCount: Int) -> Bool
}

public extension CheckVaultCreationAllowanceUseCase {
    func callAsFunction(userData: UserData?,
                        organization: Entities.Organization?,
                        vaultCount: Int) -> Bool {
        execute(userData: userData, organization: organization, vaultCount: vaultCount)
    }
}

public final class CheckVaultCreationAllowance: CheckVaultCreationAllowanceUseCase {
    public init() {}

    public func execute(userData: UserData?,
                        organization: Entities.Organization?,
                        vaultCount: Int) -> Bool {
        // If user is admin => we ignore vault policy => user can always create vaults
        guard let organization, let userData, userData.user.safeRole != .admin else {
            return true
        }

        return switch organization.settings?.vaultCreateMode {
        case .allowed:
            // Explicitly allowed
            true
        case .onlyOrgAdmins:
            // Explicitly disallowed
            false
        case .onlyOrgAdminsAndPersonalVault:
            // Only possible when no vaults
            vaultCount == 0
        default:
            // Implicitly allowed
            true
        }
    }
}
