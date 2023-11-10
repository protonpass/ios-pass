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
import XCTest

private struct DummyItem: ItemIdentifiable, Hashable, Equatable {
    let itemId: String
    let shareId: String
}

final class LocalSearchEntryDatasourceTests: XCTestCase {
    var sut: LocalSearchEntryDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testGetAllEntriesOfAllVaults() async throws {
        // Given
        let givenEntry1 = try await sut.givenInsertedEntry()
        let givenEntry2 = try await sut.givenInsertedEntry()
        let givenEntry3 = try await sut.givenInsertedEntry()

        // When
        let entries = try await sut.getAllEntries(shareId: nil)

        // Then
        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(Set([givenEntry1, givenEntry2, givenEntry3]), Set(entries))
    }

    func testGetAllEntriesOfGivenVault() async throws {
        // Given
        let givenShareId1 = String.random()
        let givenEntry1 = try await sut.givenInsertedEntry(shareID: givenShareId1)
        let givenEntry2 = try await sut.givenInsertedEntry(shareID: givenShareId1)
        let givenEntry3 = try await sut.givenInsertedEntry(shareID: givenShareId1)

        let givenShareId2 = String.random()
        let givenEntry4 = try await sut.givenInsertedEntry(shareID: givenShareId2)
        let givenEntry5 = try await sut.givenInsertedEntry(shareID: givenShareId2)
        let givenEntry6 = try await sut.givenInsertedEntry(shareID: givenShareId2)

        // When
        let allEntries = try await sut.getAllEntries(shareId: nil)
        let entriesOfShare1 = try await sut.getAllEntries(shareId: givenShareId1)
        let entriesOfShare2 = try await sut.getAllEntries(shareId: givenShareId2)

        // Then
        XCTAssertEqual(allEntries.count, 6)
        XCTAssertEqual(Set([givenEntry1, givenEntry2, givenEntry3, givenEntry4, givenEntry5, givenEntry6]),
                       Set(allEntries))

        XCTAssertEqual(entriesOfShare1.count, 3)
        XCTAssertEqual(Set([givenEntry1, givenEntry2, givenEntry3]), Set(entriesOfShare1))

        XCTAssertEqual(entriesOfShare2.count, 3)
        XCTAssertEqual(Set([givenEntry4, givenEntry5, givenEntry6]), Set(entriesOfShare2))
    }

    func testUpsertEntry() async throws {
        // Given
        let givenEntry = try await sut.givenInsertedEntry()
        let newDate = Date.now

        // When
        try await sut.upsert(item: givenEntry, date: newDate)
        let entries = try await sut.getAllEntries(shareId: nil)

        // Then
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].itemId, givenEntry.itemId)
        XCTAssertEqual(entries[0].shareId, givenEntry.shareId)
        XCTAssertEqual(entries[0].time, Int64(newDate.timeIntervalSince1970))
    }

    func testRemoveAllEntries() async throws {
        // Given
        try await sut.givenInsertedEntry()
        try await sut.givenInsertedEntry()
        try await sut.givenInsertedEntry()

        // When
        let firstEntries = try await sut.getAllEntries(shareId: nil)

        // Then
        XCTAssertEqual(firstEntries.count, 3)

        // When
        try await sut.removeAllEntries()
        let secondGetEntries = try await sut.getAllEntries(shareId: nil)

        // Then
        XCTAssertTrue(secondGetEntries.isEmpty)
    }

    func testRemoveEntry() async throws {
        // Given
        let givenEntry1 = try await sut.givenInsertedEntry()
        let givenEntry2 = try await sut.givenInsertedEntry()
        let givenEntry3 = try await sut.givenInsertedEntry()

        // When
        try await sut.remove(item: givenEntry2)
        let entries = try await sut.getAllEntries(shareId: nil)

        // Then
        XCTAssertEqual(Set([givenEntry1, givenEntry3]), Set(entries))
    }
}

extension SearchEntry {
    static func random(itemID: String = .random(),
                       shareID: String = .random(),
                       time: Int64 = .random(in: 1_000_000...2_000_000)) -> SearchEntry {
        .init(itemID: itemID, shareID: shareID, time: time)
    }
}

private extension LocalSearchEntryDatasource {
    @discardableResult
    func givenInsertedEntry(itemID: String = .random(),
                            shareID: String = .random(),
                            time: Int64 = .random(in: 1_000_000...2_000_000)) async throws -> SearchEntry {
        let item = DummyItem(itemId: itemID, shareId: shareID)
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        try await upsert(item: item, date: date)
        return .init(item: item, date: date)
    }
}
