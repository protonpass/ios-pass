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

public enum VaultCreationAllowance: Sendable, Equatable {
    case allowed
    case vaultLimitReached
    case notAllowedByOrganization
}

public protocol CheckVaultCreationAllowanceUseCase: Sendable {
    func callAsFunction(userId: String, newVaultCount: Int) async throws -> VaultCreationAllowance
}

public struct CheckVaultCreationAllowance: CheckVaultCreationAllowanceUseCase {
    private let userManager: any UserManagerProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let organizationRepository: any OrganizationRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol

    public init(userManager: any UserManagerProtocol,
                accessRepository: any AccessRepositoryProtocol,
                organizationRepository: any OrganizationRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol) {
        self.userManager = userManager
        self.accessRepository = accessRepository
        self.organizationRepository = organizationRepository
        self.shareRepository = shareRepository
    }

    public func callAsFunction(userId: String, newVaultCount: Int) async throws -> VaultCreationAllowance {
        guard newVaultCount > 0 else { return .allowed }

        let vaultCount = try await shareRepository.getShares(userId: userId)
            .count(where: \.share.isVaultRepresentation)
        let plan = try await accessRepository.getPlan(userId: userId)
        if plan.isBusinessUser,
           try await !organizationAllows(newVaultCount: newVaultCount, vaultCount: vaultCount, userId: userId) {
            return .notAllowedByOrganization
        }
        if let vaultLimit = plan.vaultLimit, vaultCount + newVaultCount > vaultLimit {
            return .vaultLimitReached
        }
        return .allowed
    }
}

private extension CheckVaultCreationAllowance {
    func organizationAllows(newVaultCount: Int, vaultCount: Int, userId: String) async throws -> Bool {
        guard let userData = try await userManager.getUserData(userId),
              userData.user.safeRole != .admin,
              let organization = try await organizationRepository.getOrganization(userId: userId) else {
            return true
        }

        return switch organization.settings?.vaultCreateMode {
        case .onlyOrgAdmins:
            false

        case .onlyOrgAdminsAndPersonalVault:
            vaultCount + newVaultCount <= 1

        default:
            true
        }
    }
}
