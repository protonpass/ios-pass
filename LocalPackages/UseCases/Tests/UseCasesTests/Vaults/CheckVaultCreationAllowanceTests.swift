//
// CheckVaultCreationAllowanceTests.swift
// Proton Pass - Created on 07/10/2026.
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
import ClientMocks
import Entities
import EntitiesMocks
import ProtonCoreLogin
import Testing
import UseCases
import UseCasesMocks

@Suite(.tags(.useCase))
struct CheckVaultCreationAllowanceTests {
    let userManager = UserManagerProtocolMock()
    let accessRepository = AccessRepositoryProtocolMock()
    let organizationRepository = OrganizationRepositoryProtocolMock()
    let shareRepository = ShareRepositoryProtocolMock()
    let member = UserData.random(role: UserRole.member.rawValue)
    let sut: CheckVaultCreationAllowance

    init() {
        userManager.stubbedGetAllUsersResult = [member]
        accessRepository.stubbedGetAccessResult = .mock(access: .mock(plan: .mockBusinessPlan))
        organizationRepository.stubbedGetOrganizationResult = .init(canUpdate: false, settings: nil)
        shareRepository.stubbedGetSharesResult = []
        sut = .init(userManager: userManager,
                    accessRepository: accessRepository,
                    organizationRepository: organizationRepository,
                    shareRepository: shareRepository)
    }

    @Test(arguments: [
        (Entities.Organization.VaultCreateMode?.none, 1, 1, VaultCreationAllowance.allowed),
        (.allowed, 1, 2, .allowed),
        (.onlyOrgAdmins, 0, 1, .notAllowedByOrganization),
        (.onlyOrgAdminsAndPersonalVault, 0, 1, .allowed),
        (.onlyOrgAdminsAndPersonalVault, 0, 2, .notAllowedByOrganization),
        (.onlyOrgAdminsAndPersonalVault, 1, 1, .notAllowedByOrganization)
    ])
    func `members follow the organization vault creation mode`(mode: Entities.Organization.VaultCreateMode?,
                                                               vaultCount: Int,
                                                               newVaultCount: Int,
                                                               expected: VaultCreationAllowance) async throws {
        organizationRepository.stubbedGetOrganizationResult = .vaultCreateMode(mode)
        shareRepository.stubbedGetSharesResult = (0..<vaultCount).map { _ in .vault() }

        let allowance = try await sut(userId: member.user.ID, newVaultCount: newVaultCount)

        #expect(allowance == expected)
    }

    @Test func `admins ignore the organization vault creation mode`() async throws {
        let admin = UserData.random(role: UserRole.admin.rawValue)
        userManager.stubbedGetAllUsersResult = [admin]
        organizationRepository.stubbedGetOrganizationResult = .vaultCreateMode(.onlyOrgAdmins)

        #expect(try await sut(userId: admin.user.ID, newVaultCount: 1) == .allowed)
    }

    @Test func `allowed without user data or organization`() async throws {
        organizationRepository.stubbedGetOrganizationResult = .vaultCreateMode(.onlyOrgAdmins)
        #expect(try await sut(userId: "unknown", newVaultCount: 1) == .allowed)

        organizationRepository.stubbedGetOrganizationResult = nil
        #expect(try await sut(userId: member.user.ID, newVaultCount: 1) == .allowed)
    }

    @Test func `organization policy is ignored for non business plans`() async throws {
        accessRepository.stubbedGetAccessResult = .mock(access: .mock(plan: .mock(vaultLimit: nil)))
        organizationRepository.stubbedGetOrganizationResult = .vaultCreateMode(.onlyOrgAdmins)

        #expect(try await sut(userId: member.user.ID, newVaultCount: 2) == .allowed)
    }

    @Test(arguments: [(1, VaultCreationAllowance.allowed), (2, .vaultLimitReached)])
    func `the plan vault limit caps the new vaults`(newVaultCount: Int,
                                                    expected: VaultCreationAllowance) async throws {
        accessRepository.stubbedGetAccessResult = .mock(access: .mock(plan: .mock(vaultLimit: 2)))
        shareRepository.stubbedGetSharesResult = [.vault()]

        #expect(try await sut(userId: member.user.ID, newVaultCount: newVaultCount) == expected)
    }

    @Test func `organization policy takes precedence over the plan vault limit`() async throws {
        accessRepository.stubbedGetAccessResult = .mock(access: .mock(plan: .mock(type: "business",
                                                                                  vaultLimit: 0)))
        organizationRepository.stubbedGetOrganizationResult = .vaultCreateMode(.onlyOrgAdmins)

        #expect(try await sut(userId: member.user.ID, newVaultCount: 1) == .notAllowedByOrganization)
    }

    @Test func `creating no vault is always allowed`() async throws {
        organizationRepository.stubbedGetOrganizationResult = .vaultCreateMode(.onlyOrgAdmins)

        #expect(try await sut(userId: member.user.ID, newVaultCount: 0) == .allowed)
    }
}

private extension Entities.Organization {
    static func vaultCreateMode(_ mode: VaultCreateMode?) -> Self {
        .init(canUpdate: false,
              settings: .init(shareMode: .default,
                              itemShareMode: .default,
                              publicLinkMode: .default,
                              forceLockSeconds: 0,
                              exportMode: .admins,
                              passwordPolicy: nil,
                              vaultCreateMode: mode,
                              aliasCreateMode: nil))
    }
}

private extension SymmetricallyEncryptedShare {
    static func vault() -> Self {
        .init(encryptedContent: nil, share: .random(targetType: Int64(TargetType.vault.rawValue)))
    }
}
