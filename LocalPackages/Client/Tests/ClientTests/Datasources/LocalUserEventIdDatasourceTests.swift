//
// LocalUserEventIdDatasourceTests.swift
// Proton Pass - Created on 16/05/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Testing

@Suite(.tags(.localDatasource))
struct LocalUserEventIdDatasourceTests {
    let sut: any LocalUserEventIdDatasourceProtocol

    init() {
        sut = LocalUserEventIdDatasource(databaseService: DatabaseService(inMemory: true))
    }

    @Test("Get, upsert and remove")
    func getUpsertAndRemove() async throws {
        let alice = String.random()
        let bob = String.random()

        let id0 = try await sut.getLastEventId(userId: alice)
        #expect(id0 == nil)

        try await sut.upsertLastEventId(userId: alice, lastEventId: "1")
        let id1 = try await sut.getLastEventId(userId: alice)
        #expect(id1 == "1")

        try await sut.upsertLastEventId(userId: alice, lastEventId: "2")
        let id2 = try await sut.getLastEventId(userId: alice)
        #expect(id2 == "2")

        try await sut.upsertLastEventId(userId: bob, lastEventId: "3")
        let id3 = try await sut.getLastEventId(userId: bob)
        #expect(id3 == "3")

        let id4 = try await sut.getLastEventId(userId: alice)
        #expect(id4 == "2")

        try await sut.removeLastEventId(userId: alice)
        let id5 = try await sut.getLastEventId(userId: alice)
        #expect(id5 == nil)

        let id6 = try await sut.getLastEventId(userId: bob)
        #expect(id6 == "3")
    }
}
