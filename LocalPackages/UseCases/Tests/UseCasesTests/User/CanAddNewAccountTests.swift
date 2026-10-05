//
// CanAddNewAccountTests.swift
// Proton Pass - Created on 05/10/2026.
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
import Testing
import UseCases

private struct UnusedError: Error {}

private struct RemoteAccessDatasourceStub: RemoteAccessDatasourceProtocol {
    let access: Access

    func getAccess(userId: String) async throws -> Access {
        access
    }

    func updatePassMonitorState(userId: String, request: UpdateMonitorStateRequest) async throws -> Access
        .Monitor {
        throw UnusedError()
    }

    func getUserPassInformations(userId: String) async throws -> PassUserInformations {
        throw UnusedError()
    }
}

@Suite(.tags(.useCase))
struct CanAddNewAccountTests {
    @Test(arguments: [
        (true, 0, true),
        (true, 1, false),
        (false, 1, true),
        (false, 2, false)
    ])
    func `only one free account is allowed across all signed in accounts`(newAccountIsFree: Bool,
                                                                          existingFreeAccounts: Int,
                                                                          expected: Bool) async throws {
        let localDatasource = LocalAccessDatasourceProtocolMock()
        localDatasource.stubbedGetAllAccessesResult = (0..<existingFreeAccounts).map { index in
            UserAccess.mock(userId: "free-\(index)", access: .mock(plan: .mockFreePlan))
        } + [UserAccess.mock(userId: "paid", access: .mock(plan: .mock(type: "plus")))]
        let newAccountPlan: Plan = newAccountIsFree ? .mockFreePlan : .mock(type: "plus")
        let sut = CanAddNewAccount(localDatasource: localDatasource,
                                   remoteDatasource: RemoteAccessDatasourceStub(access: .mock(plan: newAccountPlan)))

        #expect(try await sut(userId: "new-user") == expected)
    }
}
