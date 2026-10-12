//
// LogOutExcessFreeAccountsTests.swift
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

import ClientMocks
import Entities
import EntitiesMocks
import Testing
import UseCases

private actor LogOutUserSpy: LogOutUserUseCase {
    private(set) var loggedOutUserIds = [String]()

    func execute(userId: String) async throws -> Bool {
        loggedOutUserIds.append(userId)
        return true
    }
}

@Suite(.tags(.useCase))
struct LogOutExcessFreeAccountsTests {
    private let datasource = LocalAccessDatasourceProtocolMock()
    private let logOutUser = LogOutUserSpy()

    @Test func `nothing is logged out while there is at most one free account`() async throws {
        datasource.stubbedGetAllAccessesResult = [free("free-1"), paid("paid-1"), paid("paid-2")]

        let loggedOut = try await makeSUT()()

        #expect(!loggedOut)
        #expect(await logOutUser.loggedOutUserIds.isEmpty)
    }

    @Test func `every free account but the first is logged out`() async throws {
        datasource.stubbedGetAllAccessesResult = [free("free-1"), paid("paid-1"), free("free-2"), free("free-3")]

        let loggedOut = try await makeSUT()()

        #expect(loggedOut)
        #expect(await logOutUser.loggedOutUserIds == ["free-2", "free-3"])
    }
}

private extension LogOutExcessFreeAccountsTests {
    func makeSUT() -> LogOutExcessFreeAccounts {
        LogOutExcessFreeAccounts(datasource: datasource, logOutUser: logOutUser)
    }

    func free(_ userId: String) -> UserAccess {
        .mock(userId: userId, access: .mock(plan: .mockFreePlan))
    }

    func paid(_ userId: String) -> UserAccess {
        .mock(userId: userId, access: .mock(plan: .mock(type: "plus")))
    }
}
