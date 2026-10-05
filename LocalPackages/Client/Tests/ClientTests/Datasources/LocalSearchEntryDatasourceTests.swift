//
// LocalSearchEntryDatasourceTests.swift
// Proton Pass - Created on 17/03/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Entities
import EntitiesMocks
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalSearchEntryDatasourceTests {
    let sut: any LocalSearchEntryDatasourceProtocol =
        LocalSearchEntryDatasource(databaseService: DatabaseService(inMemory: true))

    @Test func `all entries of a user are returned across vaults`() async throws {
        // Given
        let userId = String.random()
        let givenEntry1 = try await sut.givenInsertedEntry(userID: userId)
        let givenEntry2 = try await sut.givenInsertedEntry(userID: userId)
        let givenEntry3 = try await sut.givenInsertedEntry(userID: userId)

        // When
        let entries = try await sut.getAllEntries(userId: userId)

        // Then
        #expect(entries.count == 3)
        #expect(Set([givenEntry1, givenEntry2, givenEntry3]) == Set(entries))
    }

    @Test func `entries can be fetched per user and per vault`() async throws {
        // Given
        let userId = String.random()
        let givenShareId1 = String.random()
        let givenEntry1 = try await sut.givenInsertedEntry(shareID: givenShareId1, userID: userId)
        let givenEntry2 = try await sut.givenInsertedEntry(shareID: givenShareId1, userID: userId)
        let givenEntry3 = try await sut.givenInsertedEntry(shareID: givenShareId1, userID: userId)

        let givenShareId2 = String.random()
        let givenEntry4 = try await sut.givenInsertedEntry(shareID: givenShareId2, userID: userId)
        let givenEntry5 = try await sut.givenInsertedEntry(shareID: givenShareId2, userID: userId)
        let givenEntry6 = try await sut.givenInsertedEntry(shareID: givenShareId2, userID: userId)

        // When
        let allEntries = try await sut.getAllEntries(userId: userId)
        let entriesOfShare1 = try await sut.getAllEntries(shareId: givenShareId1)
        let entriesOfShare2 = try await sut.getAllEntries(shareId: givenShareId2)

        // Then
        #expect(allEntries.count == 6)
        #expect(Set([givenEntry1, givenEntry2, givenEntry3, givenEntry4, givenEntry5, givenEntry6]) ==
            Set(allEntries))

        #expect(entriesOfShare1.count == 3)
        #expect(Set([givenEntry1, givenEntry2, givenEntry3]) == Set(entriesOfShare1))

        #expect(entriesOfShare2.count == 3)
        #expect(Set([givenEntry4, givenEntry5, givenEntry6]) == Set(entriesOfShare2))
    }

    @Test func `upserting an existing entry updates its time`() async throws {
        // Given
        let userId = String.random()
        let givenEntry = try await sut.givenInsertedEntry(userID: userId)
        let newDate = Date.now

        // When
        try await sut.upsert(item: givenEntry, userId: userId, date: newDate)
        let entries = try await sut.getAllEntries(userId: userId)

        // Then
        #expect(entries.count == 1)
        #expect(entries[0].itemId == givenEntry.itemId)
        #expect(entries[0].shareId == givenEntry.shareId)
        #expect(entries[0].time == Int64(newDate.timeIntervalSince1970))
    }

    @Test func `removing entries of a vault keeps other vaults intact`() async throws {
        // Given
        let userId = String.random()

        // When
        let entry1 = try await sut.givenInsertedEntry(userID: userId)
        let entry2 = try await sut.givenInsertedEntry(userID: userId)
        let entry3 = try await sut.givenInsertedEntry(userID: userId)

        // Then
        #expect(try await sut.getAllEntries(shareId: entry1.shareId).first == entry1)
        #expect(try await sut.getAllEntries(shareId: entry2.shareId).first == entry2)
        #expect(try await sut.getAllEntries(shareId: entry3.shareId).first == entry3)

        // When
        try await sut.removeAllEntries(shareId: entry1.shareId)

        // Then
        #expect(try await sut.getAllEntries(shareId: entry1.shareId).isEmpty)
        #expect(try await sut.getAllEntries(shareId: entry2.shareId).first == entry2)
        #expect(try await sut.getAllEntries(shareId: entry3.shareId).first == entry3)
    }

    @Test func `removing entries of a user keeps other users intact`() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        try await sut.givenInsertedEntry(userID: userId1)
        try await sut.givenInsertedEntry(userID: userId1)
        let entry1 = try await sut.givenInsertedEntry(userID: userId2)
        let entry2 = try await sut.givenInsertedEntry(userID: userId2)

        // When
        try await sut.removeAllEntries(userId: userId1)

        // Then
        #expect(try await sut.getAllEntries(userId: userId1).isEmpty)
        #expect(try await Set(sut.getAllEntries(userId: userId2)) == Set([entry1, entry2]))
    }

    @Test func `a single entry can be removed`() async throws {
        // Given
        let userId = String.random()
        let givenEntry1 = try await sut.givenInsertedEntry(userID: userId)
        let givenEntry2 = try await sut.givenInsertedEntry(userID: userId)
        let givenEntry3 = try await sut.givenInsertedEntry(userID: userId)

        // When
        try await sut.remove(item: givenEntry2)
        let entries = try await sut.getAllEntries(userId: userId)

        // Then
        #expect(Set([givenEntry1, givenEntry3]) == Set(entries))
    }
}

private extension SearchEntry {
    static func random(itemID: String = .random(),
                       shareID: String = .random(),
                       time: Int64 = .random(in: 1_000_000...2_000_000)) -> SearchEntry {
        .init(itemId: itemID, shareId: shareID, time: time)
    }
}

private extension LocalSearchEntryDatasourceProtocol {
    @discardableResult
    func givenInsertedEntry(itemID: String = .random(),
                            shareID: String = .random(),
                            userID: String = .random(),
                            time: Int64 = .random(in: 1_000_000...2_000_000)) async throws -> SearchEntry {
        let item = DummyItemIdentifiable(itemId: itemID, shareId: shareID)
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        try await upsert(item: item, userId: userID, date: date)
        return .init(item: item, date: date)
    }
}
