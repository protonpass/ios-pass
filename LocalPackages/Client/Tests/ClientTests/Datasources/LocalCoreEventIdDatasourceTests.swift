//
// LocalCoreEventIdDatasourceTests.swift
// Proton Pass - Created on 12/05/2026.
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
//

@testable import Client
import Testing

@Suite(.tags(.localDatasource))
struct LocalCoreEventIdDatasourceTests {
    let sut: any LocalCoreEventIdDatasourceProtocol

    init() {
        sut = LocalCoreEventIdDatasource(databaseService: DatabaseService(inMemory: true))
    }

    @Test
    func `Upsert, get and remove eventID by userID`() async throws {
        // Given
        let userId1 = String.random()
        let eventId1 = String.random()

        let userId2 = String.random()
        let eventId2 = String.random()

        let userId3 = String.random()

        // When
        try await sut.upsertLastEventId(userId: userId1, lastEventId: eventId1)
        try await sut.upsertLastEventId(userId: userId2, lastEventId: eventId2)

        // Then
        #expect(try await sut.getLastEventId(userId: userId1) == eventId1)
        #expect(try await sut.getLastEventId(userId: userId2) == eventId2)
        #expect(try await sut.getLastEventId(userId: userId3) == nil)

        // When
        let updatedEventId1 = String.random()
        try await sut.upsertLastEventId(userId: userId1, lastEventId: updatedEventId1)

        // Then
        #expect(try await sut.getLastEventId(userId: userId1) == updatedEventId1)

        // When
        try await sut.removeLastEventId(userId: userId1)

        // Then
        #expect(try await sut.getLastEventId(userId: userId1) == nil)
        #expect(try await sut.getLastEventId(userId: userId2) == eventId2)
        #expect(try await sut.getLastEventId(userId: userId3) == nil)
    }
}
