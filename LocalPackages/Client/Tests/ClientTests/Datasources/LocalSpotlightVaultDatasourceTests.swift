//
// LocalSpotlightVaultDatasourceTests.swift
// Proton Pass - Created on 31/01/2024.
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

@testable import Client
import Testing

@Suite(.tags(.localDatasource))
struct LocalSpotlightVaultDatasourceTests {
    let sut = LocalSpotlightVaultDatasource(databaseService: DatabaseService(inMemory: true))
}

extension LocalSpotlightVaultDatasourceTests {
    @Test func `vault ids are stored and removed per user`() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        let shareId1 = String.random()
        let shareId2 = String.random()
        let shareId3 = String.random()
        let shareId4 = String.random()

        // When
        try await sut.setIds(for: userId1, ids: [shareId1, shareId2, shareId3])
        try await sut.setIds(for: userId2, ids: [shareId4])

        // Then
        let user1ShareIds1 = try await sut.getIds(for: userId1)
        let user2ShareIds1 = try await sut.getIds(for: userId2)
        #expect(Set([shareId1, shareId2, shareId3]) == Set(user1ShareIds1))
        #expect(Set([shareId4]) == Set(user2ShareIds1))

        // When
        try await sut.removeAll(for: userId1)

        // Then
        let user1ShareIds2 = try await sut.getIds(for: userId1)
        let user2ShareIds2 = try await sut.getIds(for: userId2)
        #expect(user1ShareIds2.isEmpty)
        #expect(Set([shareId4]) == Set(user2ShareIds2))
    }
}
