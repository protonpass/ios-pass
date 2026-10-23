//
// LocalShareDatasourceTests.swift
// Proton Pass - Created on 14/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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
struct LocalShareDatasourceTests {
    let sut = LocalShareDatasource(databaseService: DatabaseService(inMemory: true))
}

extension LocalShareDatasourceTests {
    @Test func `shares are fetched by user id`() async throws {
        // Given
        let givenShares = [SymmetricallyEncryptedShare].random(randomElement: .random())
        let givenUserId = String.random()

        // When
        try await sut.upsertShares(givenShares, userId: givenUserId)
        // Populate the database with arbitrary shares
        // this is to test if fetching shares by userId correctly work
        for _ in 0...10 {
            try await sut.upsertShares([.random()], userId: .random())
        }

        // Then
        let shares = try await sut.getAllShares(userId: givenUserId)
        let shareIds = Set(shares.map(\.share.shareID))
        let givenShareIds = Set(givenShares.map(\.share.shareID))
        #expect(shareIds == givenShareIds)
    }

    @Test func `shares are fetched by vault id`() async throws {
        // Given
        let vaultId1 = String.random()
        let vaultId2 = String.random()

        let share1 = SymmetricallyEncryptedShare.random(vaultId: vaultId1)
        try await sut.upsertShares([share1], userId: .random())

        let share2 = SymmetricallyEncryptedShare.random(vaultId: vaultId1)
        try await sut.upsertShares([share2], userId: .random())

        let share3 = SymmetricallyEncryptedShare.random(vaultId: vaultId2)
        try await sut.upsertShares([share3], userId: .random())

        let share4 = SymmetricallyEncryptedShare.random(vaultId: vaultId2)
        try await sut.upsertShares([share4], userId: .random())

        let share5 = SymmetricallyEncryptedShare.random(vaultId: vaultId2)
        try await sut.upsertShares([share5], userId: .random())

        // When
        let batch1 = try await sut.getAllShares(vaultId: vaultId1)
        let batch2 = try await sut.getAllShares(vaultId: vaultId2)
        let batch3 = try await sut.getAllShares(vaultId: .random())

        // Then
        #expect(batch1.count == 2)
        #expect(batch1.contains(share1))
        #expect(batch1.contains(share2))

        #expect(batch2.count == 3)
        #expect(batch2.contains(share3))
        #expect(batch2.contains(share4))
        #expect(batch2.contains(share5))

        #expect(batch3.isEmpty)
    }

    @Test func `a share is fetched by user and share id`() async throws {
        // Given
        let givenUserId = String.random()
        let givenInsertedShare = try await sut.givenInsertedShare(userId: givenUserId)

        // When
        for _ in 0...10 {
            try await sut.upsertShares([.random()], userId: givenUserId)
        }

        let optionalShares = try await sut.getShare(userId: givenUserId,
                                                    shareId: givenInsertedShare.share.shareID)
        let share = try #require(optionalShares)
        #expect(share == givenInsertedShare)
    }

    @Test func `inserted shares are all returned`() async throws {
        // Given
        let firstShares = [SymmetricallyEncryptedShare].random(randomElement: .random())
        let secondShares = [SymmetricallyEncryptedShare].random(randomElement: .random())
        let thirdShares = [SymmetricallyEncryptedShare].random(randomElement: .random())
        let givenShares = firstShares + secondShares + thirdShares
        let givenUserId = String.random()

        // When
        try await sut.upsertShares(firstShares, userId: givenUserId)
        try await sut.upsertShares(secondShares, userId: givenUserId)
        try await sut.upsertShares(thirdShares, userId: givenUserId)

        // Then
        let shares = try await sut.getAllShares(userId: givenUserId)
        #expect(shares.count == givenShares.count)

        let shareIds = Set(shares.map(\.share.shareID))
        let givenShareIds = Set(givenShares.map(\.share.shareID))
        #expect(shareIds == givenShareIds)
    }

    @Test func `upserting a share with an existing id replaces it`() async throws {
        // Given
        let givenUserId = String.random()
        let insertedShare = try await sut.givenInsertedShare(userId: givenUserId)
        // Only copy the shareId from givenShare
        let updatedShare = SymmetricallyEncryptedShare(encryptedContent: .random(),
                                                       share: .random(shareId: insertedShare.share.shareID))

        // When
        try await sut.upsertShares([updatedShare], userId: givenUserId)

        // Then
        let shares = try await sut.getAllShares(userId: givenUserId)
        #expect(shares.count == 1)

        let share = try #require(shares.first)
        #expect(share == updatedShare)
    }

    @Test func `a single share can be removed`() async throws {
        // Given
        let userId = String.random()
        let firstShare = SymmetricallyEncryptedShare.random()
        let secondShare = SymmetricallyEncryptedShare.random()
        let thirdShare = SymmetricallyEncryptedShare.random()

        // When
        try await sut.upsertShares([firstShare, secondShare, thirdShare], userId: userId)
        try await sut.removeShare(shareId: secondShare.share.shareID, userId: userId)

        // Then
        let shares = try await sut.getAllShares(userId: userId)
        #expect(shares.count == 2)
        #expect(shares.contains(where: { $0.share.shareID == firstShare.share.shareID }))
        #expect(shares.contains(where: { $0.share.shareID == thirdShare.share.shareID }))
    }

    @Test func `removing all shares of a user keeps other users intact`() async throws {
        // Given
        let givenFirstUserId = String.random()
        let givenFirstUserShares = [SymmetricallyEncryptedShare].random(randomElement: .random())

        let givenSecondUserId = String.random()
        let givenSecondUserShares = [SymmetricallyEncryptedShare].random(randomElement: .random())

        // When
        try await sut.upsertShares(givenFirstUserShares, userId: givenFirstUserId)
        try await sut.upsertShares(givenSecondUserShares, userId: givenSecondUserId)

        // Then
        let firstUserSharesFirstGet = try await sut.getAllShares(userId: givenFirstUserId)
        #expect(firstUserSharesFirstGet.count == givenFirstUserShares.count)

        let secondUserSharesFirstGet = try await sut.getAllShares(userId: givenSecondUserId)
        #expect(secondUserSharesFirstGet.count == givenSecondUserShares.count)

        // When
        try await sut.removeAllShares(userId: givenFirstUserId)

        // Then
        let firstUserSharesSecondGet = try await sut.getAllShares(userId: givenFirstUserId)
        #expect(firstUserSharesSecondGet.isEmpty)

        let secondUserSharesSecondGet = try await sut.getAllShares(userId: givenSecondUserId)
        #expect(secondUserSharesSecondGet.count == givenSecondUserShares.count)
    }
}

extension LocalShareDatasource {
    func givenInsertedShare(userId: String? = nil) async throws -> SymmetricallyEncryptedShare {
        let share = SymmetricallyEncryptedShare.random()
        try await upsertShares([share], userId: userId ?? .random())
        return share
    }
}
