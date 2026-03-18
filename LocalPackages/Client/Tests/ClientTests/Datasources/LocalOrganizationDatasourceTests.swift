//
// LocalOrganizationDatasourceTests.swift
// Proton Pass - Created on 19/03/2024.
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
import Testing

@Suite(.tags(.localDatasource))
struct LocalOrganizationDatasourceTests {
    let sut: LocalOrganizationDatasourceProtocol

    init() {
        sut = LocalOrganizationDatasource(databaseService: DatabaseService(inMemory: true))
    }
}

extension LocalOrganizationDatasourceTests {
    @Test
    func `Upsert organizations`() async throws {
        // Given
        // Insert organization for the first time
        let userId = String.random()
        let org1 = Organization(canUpdate: true,
                                settings: .init(shareMode: .restricted,
                                                itemShareMode: .enabled,
                                                publicLinkMode: .enabled,
                                                forceLockSeconds: 100,
                                                exportMode: .admins,
                                                passwordPolicy: PasswordPolicy.default,
                                                vaultCreateMode: .allowed,
                                                aliasCreateMode: .allowedForAllMembers))

        // When
        try await sut.upsertOrganization(org1, userId: userId)
        let result1 = try #require(await sut.getOrganization(userId: userId))

        // Then
        #expect(result1 == org1)

        // Given
        // Override the organization
        let org2 = Organization(canUpdate: false,
                                settings: .init(shareMode: .unrestricted,
                                                itemShareMode: .disabled,
                                                publicLinkMode: .enabled,
                                                forceLockSeconds: 300,
                                                exportMode: .anyone,
                                                passwordPolicy:  PasswordPolicy.default,
                                                vaultCreateMode: .onlyOrgAdmins,
                                                aliasCreateMode: .nobody))

        // When
        try await sut.upsertOrganization(org2, userId: userId)
        let result2 = try #require(await sut.getOrganization(userId: userId))

        // Then
        #expect(result2 == org2)
    }

    @Test
    func `Remove organization`() async throws {
        // Given
        let userId = String.random()
        let org1 = Organization(canUpdate: true,
                                settings: .init(shareMode: .restricted,
                                                itemShareMode: .disabled,
                                                publicLinkMode: .enabled,
                                                forceLockSeconds: 100,
                                                exportMode: .admins,
                                                passwordPolicy: PasswordPolicy.default,
                                                vaultCreateMode: .onlyOrgAdmins,
                                                aliasCreateMode: .allowedForAllMembers))

        // When
        try await sut.upsertOrganization(org1, userId: userId)

        // Then
        try #expect(await sut.getOrganization(userId: userId) == org1)

        // When
        try await sut.removeOrganization(userId: userId)

        // Then
        #expect(await sut.getOrganization(userId: userId) == nil)
    }
}
