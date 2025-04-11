//
// LocalPasswordDatasourceTests.swift
// Proton Pass - Created on 09/04/2025.
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

@testable import Client
import Core
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalPasswordDatasourceTests {
    let sut: any LocalPasswordDatasourceProtocol

    init() {
        sut = LocalPasswordDatasource(databaseService: DatabaseService(inMemory: true))
    }

    @Test("Get all passwords")
    func getAllPasswords() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()
        let id1 = String.random()
        let id2 = String.random()
        let id3 = String.random()
        let id4 = String.random()
        try await insertPassword(userId: userId1, id: id1, creationTime: 4)
        try await insertPassword(userId: userId2, id: id2, creationTime: 8)
        try await insertPassword(userId: userId1, id: id3, creationTime: 1)
        try await insertPassword(userId: userId2, id: id4, creationTime: 9)

        // When
        let passwords1 = try await sut.getAllPasswords(userId: userId1)
        let passwords2 = try await sut.getAllPasswords(userId: userId2)

        // Then
        #expect(passwords1.count == 2)
        #expect(passwords1[0].id == id1)
        #expect(passwords1[1].id == id3)

        #expect(passwords2.count == 2)
        #expect(passwords2[0].id == id4)
        #expect(passwords2[1].id == id2)
    }

    @Test("Get encrypted password")
    func getEncryptedPassword() async throws {
        // Given
        let id = String.random()
        let value = String.random()
        try await insertPassword(id: id, value: value)

        // Insert several more
        for _ in 0..<10 {
            try await insertPassword()
        }

        // When
        let retrievedValue = try await sut.getEncryptedPassword(id: id)

        // Then
        #expect(retrievedValue == value)
    }

    @Test("Delete all passwords")
    func deleteAllPasswords() async throws {
        // Given
        let userId = String.random()
        for _ in 0..<10 {
            try await insertPassword(userId: userId)
        }

        // When
        try await sut.deleteAllPasswords(userId: userId)
        let passwords = try await sut.getAllPasswords(userId: userId)

        // Then
        #expect(passwords.isEmpty)
    }

    @Test("Delete a precise password")
    func deletePrecisePassword() async throws {
        // Given
        let userId = String.random()
        let id1 = String.random()
        let id2 = String.random()
        let id3 = String.random()
        let id4 = String.random()

        try await insertPassword(userId: userId, id: id1)
        try await insertPassword(userId: userId, id: id2)
        try await insertPassword(userId: userId, id: id3)
        try await insertPassword(userId: userId, id: id4)

        // When
        try await sut.deletePassword(id: id2)
        let passwords = try await sut.getAllPasswords(userId: userId)

        // Then
        #expect(passwords.count == 3)
        #expect(passwords.contains(where: { $0.id == id1 }))
        #expect(passwords.contains(where: { $0.id == id3 }))
        #expect(passwords.contains(where: { $0.id == id4 }))
    }

    @Test("Delete passwords with cut-off time")
    func deletePasswordsWithCutOffTime() async throws {
        // Given
        let userId = String.random()
        let id1 = String.random()
        let id2 = String.random()
        let id3 = String.random()
        let id4 = String.random()

        try await insertPassword(userId: userId, id: id1, creationTime: 1)
        try await insertPassword(userId: userId, id: id2, creationTime: 2)
        try await insertPassword(userId: userId, id: id3, creationTime: 3)
        try await insertPassword(userId: userId, id: id4, creationTime: 4)

        // When
        try await sut.deletePasswords(cutOffTimestamp: 2)
        let passwords = try await sut.getAllPasswords(userId: userId)

        // Then
        #expect(passwords.count == 2)
        #expect(passwords.contains(where: { $0.id == id3 }))
        #expect(passwords.contains(where: { $0.id == id4 }))
    }
}

private extension LocalPasswordDatasourceTests {
    func insertPassword(userId: String = .random(),
                        id: String =  UUID().uuidString,
                        creationTime: Int = .random(in: 1...1_000),
                        value: String = .random()) async throws {
        try await sut.insertPassword(userId: userId,
                                     id: id,
                                     symmetricallyEncryptedValue: value,
                                     creationTime: TimeInterval(creationTime))
    }
}
