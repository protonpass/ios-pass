//  
// LocalCompromisedPasswordDatasourceTests.swift
// Proton Pass - Created on 07/07/2026.
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

import Foundation
import Entities
@testable import Client
import Testing

// MARK: - Test helpers

private struct TestItem: ItemIdentifiable {
    let shareId: String
    let itemId: String
    let folderId: String? = nil
}

private extension ItemIdentifiable {
    var asTestItem: TestItem { TestItem(shareId: shareId, itemId: itemId) }
}

extension CompromisedPasswordCheck: @retroactive ItemIdentifiable {
    public var folderId: String? {
        nil
    }
}

@Suite(.tags(.localDatasource))
struct LocalCompromisedPasswordDatasourceTests {
    let sut: any LocalCompromisedPasswordDatasourceProtocol
    
    init() {
        sut = LocalCompromisedPasswordDatasource(databaseService: DatabaseService(inMemory: true))
    }
    
    @Test func `getChecks returns empty array for a user with no persisted checks`() async throws {
        let checks = try await sut.getChecks(userId: UUID().uuidString)
        #expect(checks.isEmpty)
    }
    
    @Test func `upsert then getChecks round-trips every field`() async throws {
        let userId = UUID().uuidString
        let expected = CompromisedPasswordCheck.random()
        
        try await sut.upsert([expected], userId: userId)
        let result = try await sut.getChecks(userId: userId)
        
        // Full Equatable comparison - pins that no field (etag, prefix, hash…) is dropped
        // or transformed by the persistence layer.
        #expect(result == [expected])
    }
    
    @Test func `empty etag round-trips as empty, not nil-coalesced garbage`() async throws {
        let userId = UUID().uuidString
        let check = CompromisedPasswordCheck.random(etag: "")
        
        try await sut.upsert([check], userId: userId)
        let result = try await sut.getChecks(userId: userId)
        
        #expect(result.first?.etag == "")
    }
    
    // Pins the Core Data attribute width: values beyond Int32.max must survive.
    @Test(arguments: [0, 1, Int(Int32.max), Int(Int32.max) + 1])
    func `breachCount round-trips at boundary values`(breachCount: Int) async throws {
        let userId = UUID().uuidString
        let check = CompromisedPasswordCheck.random(breachCount: breachCount)
        
        try await sut.upsert([check], userId: userId)
        let result = try await sut.getChecks(userId: userId)
        
        #expect(result.first?.breachCount == breachCount)
    }
    
    @Test func `getChecks is scoped to the given user`() async throws {
        let userA = UUID().uuidString
        let userB = UUID().uuidString
        let checkA = CompromisedPasswordCheck.random()
        let checkB = CompromisedPasswordCheck.random()
        
        try await sut.upsert([checkA], userId: userA)
        try await sut.upsert([checkB], userId: userB)
        
        let resultsA = try await sut.getChecks(userId: userA)
        let resultsB = try await sut.getChecks(userId: userB)
        
        #expect(resultsA == [checkA])
        #expect(resultsB == [checkB])
    }
    
    // MARK: upsert
    
    @Test func `upsert with same shareId and itemId replaces instead of duplicating`() async throws {
        let userId = UUID().uuidString
        let original = CompromisedPasswordCheck.random()
        // Same identity, everything else changed - models a password change + re-check.
        let updated = CompromisedPasswordCheck.random(shareId: original.shareId,
                                                      itemId: original.itemId)
        
        try await sut.upsert([original], userId: userId)
        try await sut.upsert([updated], userId: userId)
        
        let result = try await sut.getChecks(userId: userId)
        #expect(result == [updated])
    }
    
    @Test func `upsert updates existing rows and inserts new ones in the same call`() async throws {
        let userId = UUID().uuidString
        let existing = CompromisedPasswordCheck.random()
        let untouched = CompromisedPasswordCheck.random()
        try await sut.upsert([existing, untouched], userId: userId)

        let updated = CompromisedPasswordCheck.random(shareId: existing.shareId,
                                                      itemId: existing.itemId)
        let inserted = CompromisedPasswordCheck.random()
        try await sut.upsert([updated, inserted], userId: userId)

        let result = try await sut.getChecks(userId: userId)
        #expect(Set(result.map(\.id)) == [existing.id, untouched.id, inserted.id])
        #expect(result.first { $0.id == existing.id } == updated)
        #expect(result.first { $0.id == untouched.id } == untouched)
        #expect(result.first { $0.id == inserted.id } == inserted)
    }

    @Test func `same itemId under different shareIds persists as distinct rows`() async throws {
        let userId = UUID().uuidString
        let itemId = UUID().uuidString
        let a = CompromisedPasswordCheck.random(shareId: UUID().uuidString, itemId: itemId)
        let b = CompromisedPasswordCheck.random(shareId: UUID().uuidString, itemId: itemId)
        
        try await sut.upsert([a, b], userId: userId)
        
        let result = try await sut.getChecks(userId: userId)
        #expect(Set(result.map(\.id)) == Set([a.id, b.id]))
    }
    
    @Test func `identical check upserted for two users is stored per user`() async throws {
        // Pins that userId participates in the conflict identity: same (shareId, itemId)
        // for two users must not overwrite each other.
        let userA = UUID().uuidString
        let userB = UUID().uuidString
        let shared = CompromisedPasswordCheck.random()
        
        try await sut.upsert([shared], userId: userA)
        try await sut.upsert([shared], userId: userB)
        try await sut.removeAll(userId: userA)
        
        let resultsB = try await sut.getChecks(userId: userB)
        #expect(resultsB == [shared])
    }
    
    @Test func `upsert of an empty array is a no-op`() async throws {
        let userId = UUID().uuidString
        let existing = CompromisedPasswordCheck.random()
        try await sut.upsert([existing], userId: userId)
        
        try await sut.upsert([], userId: userId)
        
        let result = try await sut.getChecks(userId: userId)
        #expect(result == [existing])
    }
    
    @Test func `batch upsert containing duplicate identities keeps a single row`() async throws {
        // Two entries with the same (shareId, itemId) in ONE call - last-write-wins
        // vs. duplicate-rows is a real behavioral fork; this pins it to "single row".
        let userId = UUID().uuidString
        let first = CompromisedPasswordCheck.random()
        let second = CompromisedPasswordCheck.random(shareId: first.shareId, itemId: first.itemId)
        
        try await sut.upsert([first, second], userId: userId)
        
        let result = try await sut.getChecks(userId: userId)
        #expect(result.count == 1)
    }
    
    // MARK: remove(userId:staleItemIds:)
    
    @Test func `remove staleItemIds deletes only the listed items`() async throws {
        let userId = UUID().uuidString
        let stale = CompromisedPasswordCheck.random()
        let kept = CompromisedPasswordCheck.random()
        try await sut.upsert([stale, kept], userId: userId)
        
        try await sut.remove(userId: userId, staleItemIds: [stale.asTestItem])
        
        let result = try await sut.getChecks(userId: userId)
        #expect(result == [kept])
    }
    
    @Test func `remove staleItemIds matches the exact share and item pair`() async throws {
        let userId = UUID().uuidString
        let staleA = CompromisedPasswordCheck.random(shareId: "shareA", itemId: "item1")
        let staleB = CompromisedPasswordCheck.random(shareId: "shareB", itemId: "item2")
        // Crosses the stale pairs: an IN/IN predicate would wrongly delete both
        let keptA = CompromisedPasswordCheck.random(shareId: "shareB", itemId: "item1")
        let keptB = CompromisedPasswordCheck.random(shareId: "shareA", itemId: "item2")
        try await sut.upsert([staleA, staleB, keptA, keptB], userId: userId)

        try await sut.remove(userId: userId, staleItemIds: [staleA.asTestItem, staleB.asTestItem])

        let result = try await sut.getChecks(userId: userId)
        #expect(Set(result.map(\.id)) == [keptA.id, keptB.id])
    }

    @Test func `remove staleItemIds does not touch another user's identical item`() async throws {
        let userA = UUID().uuidString
        let userB = UUID().uuidString
        let check = CompromisedPasswordCheck.random()
        try await sut.upsert([check], userId: userA)
        try await sut.upsert([check], userId: userB)
        
        try await sut.remove(userId: userA, staleItemIds: [check.asTestItem])
        
        let resultsA = try await sut.getChecks(userId: userA)
        let resultsB = try await sut.getChecks(userId: userB)
        #expect(resultsA.isEmpty)
        #expect(resultsB == [check])
    }
    
    @Test func `remove with empty staleItemIds is a no-op`() async throws {
        let userId = UUID().uuidString
        let check = CompromisedPasswordCheck.random()
        try await sut.upsert([check], userId: userId)
        
        try await sut.remove(userId: userId, staleItemIds: [])
        
        let result = try await sut.getChecks(userId: userId)
        #expect(result == [check])
    }
    
    @Test func `remove of a non-existent item does not throw and leaves data intact`() async throws {
        let userId = UUID().uuidString
        let check = CompromisedPasswordCheck.random()
        try await sut.upsert([check], userId: userId)
        
        try await sut.remove(userId: userId, staleItemIds: [TestItem(shareId: "x", itemId: "y")])
        
        let result = try await sut.getChecks(userId: userId)
        #expect(result == [check])
    }
    
    // MARK: removeAll(userId:)
    
    @Test func `removeAll deletes every check for the user and only that user`() async throws {
        let userA = UUID().uuidString
        let userB = UUID().uuidString
        try await sut.upsert([.random(), .random(), .random()], userId: userA)
        let checkB = CompromisedPasswordCheck.random()
        try await sut.upsert([checkB], userId: userB)
        
        try await sut.removeAll(userId: userA)
        
        let resultsA = try await sut.getChecks(userId: userA)
        let resultsB = try await sut.getChecks(userId: userB)
        #expect(resultsA.isEmpty)
        #expect(resultsB == [checkB])
    }
    
    @Test func `removeAll on a user with no checks does not throw`() async throws {
        try await sut.removeAll(userId: UUID().uuidString)
    }
    
    // MARK: Concurrency
    
    @Test func `concurrent upserts of disjoint items all persist`() async throws {
        // The protocol is Sendable and async, so concurrent callers are a supported usage
        let userId = UUID().uuidString
        let checks = (0..<50).map { _ in CompromisedPasswordCheck.random() }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for check in checks {
                group.addTask {
                    try await sut.upsert([check], userId: userId)
                }
            }
            try await group.waitForAll()
        }
        
        let result = try await sut.getChecks(userId: userId)
        #expect(Set(result.map(\.id)) == Set(checks.map(\.id)))
    }
    
    @Test func `concurrent upserts of the same identity converge to a single row`() async throws {
        // Races the conflict-resolution path. We can't assert WHICH write wins,
        // only that the invariant (one row per identity) holds.
        let userId = UUID().uuidString
        let base = CompromisedPasswordCheck.random()
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    let variant = CompromisedPasswordCheck.random(shareId: base.shareId,
                                                                  itemId: base.itemId)
                    try await sut.upsert([variant], userId: userId)
                }
            }
            try await group.waitForAll()
        }
        
        let result = try await sut.getChecks(userId: userId)
        #expect(result.count == 1)
    }
}
