//
// LocalItemTextAutoFillDatasourceTests.swift
// Proton Pass - Created on 10/10/2024.
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
import Entities
import EntitiesMocks
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalItemTextAutoFillDatasourceTests {
    let sut: any LocalItemTextAutoFillDatasourceProtocol

    init() {
        sut = LocalItemTextAutoFillDatasource(databaseService: DatabaseService(inMemory: true))
    }

    @Test("Get items by userID, sorted by time descending")
    func get() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        for _ in 0...5 {
            try await sut.givenInsertedEntry(userID: userId1)
            try await sut.givenInsertedEntry(userID: userId2)
        }

        // When
        let itemsForUser1 = try await sut.getMostRecentItems(userId: userId1, count: 3)
        let itemsForUser2 = try await sut.getMostRecentItems(userId: userId2, count: 4)

        // Then
        #expect(itemsForUser1.count == 3)
        #expect(itemsForUser1 == itemsForUser1.sorted(by: { $0.timestamp > $1.timestamp }))

        #expect(itemsForUser2.count == 4)
        #expect(itemsForUser2 == itemsForUser2.sorted(by: { $0.timestamp > $1.timestamp }))
    }

    @Test("Upsert items")
    func upsert() async throws {
        // Given
        let userId = String.random()
        let item = try await sut.givenInsertedEntry(userID: userId)
        let date = Date.now

        // When
        try await sut.upsert(item: item, userId: userId, date: date)
        let items = try await sut.getMostRecentItems(userId: userId, count: 10)
        let updatedItem = try #require(items.first)

        // Then
        #expect(items.count == 1)
        #expect(updatedItem.shareId == item.shareId)
        #expect(updatedItem.itemId == item.itemId)
        #expect(Int(updatedItem.timestamp) == Int(date.timeIntervalSince1970))
    }

    @Test("Remove all items")
    func removeAll() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        for _ in 0...5 {
            try await sut.givenInsertedEntry(userID: userId1)
            try await sut.givenInsertedEntry(userID: userId2)
        }

        // When
        try await sut.removeAll()
        let items1 = try await sut.getMostRecentItems(userId: userId1, count: 100)
        let items2 = try await sut.getMostRecentItems(userId: userId2, count: 100)

        // Then
        #expect(items1.isEmpty)
        #expect(items2.isEmpty)
    }
}

private extension LocalItemTextAutoFillDatasourceProtocol {
    @discardableResult
    func givenInsertedEntry(itemID: String = .random(),
                            shareID: String = .random(),
                            userID: String = .random(),
                            time: Int64 = .random(in: 1_000_000...2_000_000))
    async throws -> ItemTextAutoFill {
        let item = DummyItemIdentifiable(itemId: itemID, shareId: shareID)
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        try await upsert(item: item, userId: userID, date: date)
        return .init(shareId: item.shareId,
                     itemId: item.itemId,
                     timestamp: TimeInterval(time),
                     userId: userID)
    }
}
