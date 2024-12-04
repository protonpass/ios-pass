//
// LocalNotificationTimeDatasourceTests.swift
// Proton Pass - Created on 04/12/2024.
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

@testable import Client
import Testing

@Suite(.tags(.localDatasource))
struct LocalNotificationTimeDatasourceTests {
    let sut: any LocalNotificationTimeDatasourceProtocol

    init() {
        sut = LocalNotificationTimeDatasource(databaseService: DatabaseService(inMemory: true))
    }

    @Test("Get and upsert timestamp")
    func getAndUpsert() async throws {
        let userId1 = String.random()
        let userId2 = String.random()

        try await sut.upsertNotificationTime(1, for: userId1)
        try await sut.upsertNotificationTime(2, for: userId1)
        try await sut.upsertNotificationTime(3, for: userId2)

        let result1 = try await sut.getNotificationTime(for: userId1)
        #expect(result1 == 2)

        let result2 = try await sut.getNotificationTime(for: userId2)
        #expect(result2 == 3)
    }
}
