//
// GetOrganizationSettingsTests.swift
// Proton Pass - Created on 26/10/2026.
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

import ClientMocks
import Combine
import Entities
import EntitiesMocks
import Testing
import UseCases

@Suite(.tags(.useCase))
struct GetOrganizationSettingsTests {
    private let accessRepository = AccessRepositoryProtocolMock()
    private let organizationRepository = OrganizationRepositoryProtocolMock()
    private let settings = Organization.Settings(shareMode: .unrestricted,
                                                 itemShareMode: .enabled,
                                                 publicLinkMode: .enabled,
                                                 forceLockSeconds: 0,
                                                 exportMode: .anyone,
                                                 passwordPolicy: nil,
                                                 vaultCreateMode: nil,
                                                 aliasCreateMode: nil)
    private let businessAccess = UserAccess.mock(access: .mock(plan: .mockBusinessPlan))

    init() {
        organizationRepository.stubbedGetOrganizationResult = .init(canUpdate: false, settings: settings)
    }

    @Test func `loads access when none has been published`() async throws {
        accessRepository.stubbedAccess = .init(nil)
        accessRepository.stubbedGetAccessResult = businessAccess

        let result = try await sut.execute()

        #expect(result == settings)
        #expect(accessRepository.invokedGetAccessCount == 1)
    }

    @Test func `uses published access without loading it`() async throws {
        accessRepository.stubbedAccess = .init(businessAccess)

        let result = try await sut.execute()

        #expect(result == settings)
        #expect(accessRepository.invokedGetAccessCount == 0)
    }
}

private extension GetOrganizationSettingsTests {
    var sut: GetOrganizationSettings {
        GetOrganizationSettings(accessRepository: accessRepository,
                                organizationRepository: organizationRepository)
    }
}
