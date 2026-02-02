//
// LocalFolderDatasourceTests.swift
// Proton Pass - Created on 02/02/2026.
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

@testable import Client
import Entities
import EntitiesMocks
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalFolderDatasourceTests {
    let sut = LocalFolderDatasource(databaseService: DatabaseService(inMemory: true))
}

// MARK: - getAllFolders Tests

extension LocalFolderDatasourceTests {
    @Test("Get all folders by user returns only folders for that user")
    func getAllFoldersByUser() async throws {
        // Given
        let userId = String.random()
        let givenFolders = [
            SymmetricallyEncryptedFolder.random(userId: userId),
            SymmetricallyEncryptedFolder.random(userId: userId),
            SymmetricallyEncryptedFolder.random(userId: userId)
        ]

        // When
        try await sut.upsertFolders(givenFolders, userId: userId)

        // Add folders for other users
        for _ in 0..<5 {
            try await sut.upsertFolders([.random()], userId: .random())
        }

        // Then
        let folders = try await sut.getAllFolders(userId: userId)
        #expect(folders.count == givenFolders.count)

        let folderIds = Set(folders.map(\.folderId))
        let givenFolderIds = Set(givenFolders.map(\.folderId))
        #expect(folderIds == givenFolderIds)
    }

    @Test("Get all folders returns empty when no folders exist for user")
    func getAllFoldersReturnsEmptyForNonExistentUser() async throws {
        // Given
        let userId = String.random()
        try await sut.upsertFolders([.random()], userId: .random())

        // When
        let folders = try await sut.getAllFolders(userId: userId)

        // Then
        #expect(folders.isEmpty)
    }
}

// MARK: - getFolder Tests

extension LocalFolderDatasourceTests {
    @Test("Get specific folder by shareId and folderId")
    func getFolder() async throws {
        // Given
        let shareId = String.random()
        let folderId = String.random()
        let userId = String.random()
        let folder = Folder.random(vaultId: shareId, folderId: folderId)
        let encryptedFolder = SymmetricallyEncryptedFolder(
            shareId: shareId,
            userId: userId,
            folder: folder,
            encryptedContent: .random()
        )
        try await sut.upsertFolders([encryptedFolder], userId: userId)

        // Add other folders
        for _ in 0..<5 {
            try await sut.upsertFolders([.random()], userId: userId)
        }

        // When
        let retrievedFolder = try await sut.getFolder(shareId: shareId, folderId: folderId)

        // Then
        let result = try #require(retrievedFolder)
        #expect(result.folderId == folderId)
        #expect(result.shareId == shareId)
    }

    @Test("Get folder returns nil when folder does not exist")
    func getFolderReturnsNilWhenNotFound() async throws {
        // Given
        try await sut.upsertFolders([.random()], userId: .random())

        // When
        let folder = try await sut.getFolder(shareId: .random(), folderId: .random())

        // Then
        #expect(folder == nil)
    }
}

// MARK: - upsertFolders Tests

extension LocalFolderDatasourceTests {
    @Test("Insert multiple folders")
    func insertFolders() async throws {
        // Given
        let userId = String.random()
        let shareId = String.random()
        let firstBatch = [
            SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId),
            SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId)
        ]
        let secondBatch = [
            SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId),
            SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId),
            SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId)
        ]

        // When
        try await sut.upsertFolders(firstBatch, userId: userId)
        try await sut.upsertFolders(secondBatch, userId: userId)

        // Then
        let folders = try await sut.getAllFolders(userId: userId)
        #expect(folders.count == 5)

        let allGivenFolderIds = Set((firstBatch + secondBatch).map(\.folderId))
        let retrievedFolderIds = Set(folders.map(\.folderId))
        #expect(retrievedFolderIds == allGivenFolderIds)
    }

    @Test("Update existing folder")
    func updateFolder() async throws {
        // Given
        let userId = String.random()
        let shareId = String.random()
        let folderId = String.random()

        let originalFolder = Folder.random(vaultId: shareId, folderId: folderId, content: "original")
        let originalEncryptedFolder = SymmetricallyEncryptedFolder(
            shareId: shareId,
            userId: userId,
            folder: originalFolder,
            encryptedContent: "original-encrypted"
        )
        try await sut.upsertFolders([originalEncryptedFolder], userId: userId)

        // When
        let updatedFolder = Folder.random(vaultId: shareId, folderId: folderId, content: "updated")
        let updatedEncryptedFolder = SymmetricallyEncryptedFolder(
            shareId: shareId,
            userId: userId,
            folder: updatedFolder,
            encryptedContent: "updated-encrypted"
        )
        try await sut.upsertFolders([updatedEncryptedFolder], userId: userId)

        // Then
        let folders = try await sut.getAllFolders(userId: userId)
        #expect(folders.count == 1)

        let folder = try #require(folders.first)
        #expect(folder.encryptedContent == "updated-encrypted")
        #expect(folder.folder.content == "updated")
    }
}

// MARK: - deleteFolders Tests

extension LocalFolderDatasourceTests {
    @Test("Delete folders by ElementIdentifiable")
    func deleteFoldersByElementIdentifiable() async throws {
        // Given
        let userId = String.random()
        let shareId = String.random()

        let folder1 = SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId)
        let folder2 = SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId)
        let folder3 = SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId)

        try await sut.upsertFolders([folder1, folder2, folder3], userId: userId)

        let initialFolders = try await sut.getAllFolders(userId: userId)
        #expect(initialFolders.count == 3)

        // When - Delete folder2
        try await sut.deleteFolders(userId: userId, folders: [folder2])

        // Then
        let remainingFolders = try await sut.getAllFolders(userId: userId)
        #expect(remainingFolders.count == 2)

        let remainingIds = Set(remainingFolders.map(\.folderId))
        #expect(remainingIds.contains(folder1.folderId))
        #expect(!remainingIds.contains(folder2.folderId))
        #expect(remainingIds.contains(folder3.folderId))
    }

    @Test("Delete folders by folderIds and shareId")
    func deleteFoldersByIds() async throws {
        // Given
        let userId = String.random()
        let shareId = String.random()

        let folder1 = SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId)
        let folder2 = SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId)
        let folder3 = SymmetricallyEncryptedFolder.random(shareId: shareId, userId: userId)

        try await sut.upsertFolders([folder1, folder2, folder3], userId: userId)

        // When - Delete folder1 and folder3
        try await sut.deleteFolders(
            userId: userId,
            folderIds: [folder1.folderId, folder3.folderId],
            shareId: shareId
        )

        // Then
        let remainingFolders = try await sut.getAllFolders(userId: userId)
        #expect(remainingFolders.count == 1)
        #expect(remainingFolders.first?.folderId == folder2.folderId)
    }
}

// MARK: - removeAllFolders Tests

extension LocalFolderDatasourceTests {
    @Test("Remove all folders globally")
    func removeAllFoldersGlobally() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        try await sut.upsertFolders([.random(userId: userId1), .random(userId: userId1)], userId: userId1)
        try await sut.upsertFolders([.random(userId: userId2), .random(userId: userId2)], userId: userId2)

        let initialUser1Folders = try await sut.getAllFolders(userId: userId1)
        let initialUser2Folders = try await sut.getAllFolders(userId: userId2)
        #expect(initialUser1Folders.count == 2)
        #expect(initialUser2Folders.count == 2)

        // When
        try await sut.removeAllFolders()

        // Then
        let user1Folders = try await sut.getAllFolders(userId: userId1)
        let user2Folders = try await sut.getAllFolders(userId: userId2)
        #expect(user1Folders.isEmpty)
        #expect(user2Folders.isEmpty)
    }

    @Test("Remove all folders by userId")
    func removeAllFoldersByUserId() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        try await sut.upsertFolders([.random(userId: userId1), .random(userId: userId1)], userId: userId1)
        try await sut.upsertFolders([.random(userId: userId2), .random(userId: userId2)], userId: userId2)

        // When
        try await sut.removeAllFolders(userId: userId1)

        // Then
        let user1Folders = try await sut.getAllFolders(userId: userId1)
        let user2Folders = try await sut.getAllFolders(userId: userId2)
        #expect(user1Folders.isEmpty)
        #expect(user2Folders.count == 2)
    }

    @Test("Remove all folders by shareId")
    func removeAllFoldersByShareId() async throws {
        // Given
        let userId = String.random()
        let shareId1 = String.random()
        let shareId2 = String.random()

        try await sut.upsertFolders([
            .random(shareId: shareId1, userId: userId),
            .random(shareId: shareId1, userId: userId)
        ], userId: userId)

        try await sut.upsertFolders([
            .random(shareId: shareId2, userId: userId),
            .random(shareId: shareId2, userId: userId),
            .random(shareId: shareId2, userId: userId)
        ], userId: userId)

        let initialFolders = try await sut.getAllFolders(userId: userId)
        #expect(initialFolders.count == 5)

        // When
        try await sut.removeAllFolders(shareId: shareId1)

        // Then
        let remainingFolders = try await sut.getAllFolders(userId: userId)
        #expect(remainingFolders.count == 3)

        let remainingShareIds = Set(remainingFolders.map(\.shareId))
        #expect(!remainingShareIds.contains(shareId1))
        #expect(remainingShareIds.contains(shareId2))
    }
}

// MARK: - Edge Cases

extension LocalFolderDatasourceTests {
    @Test("Upsert empty array does nothing")
    func upsertEmptyArray() async throws {
        // Given
        let userId = String.random()

        // When
        try await sut.upsertFolders([], userId: userId)

        // Then
        let folders = try await sut.getAllFolders(userId: userId)
        #expect(folders.isEmpty)
    }

    @Test("Folder with parent folder relationship")
    func folderWithParentRelationship() async throws {
        // Given
        let userId = String.random()
        let shareId = String.random()
        let parentFolderId = String.random()
        let childFolderId = String.random()

        let parentFolder = Folder.random(vaultId: shareId, folderId: parentFolderId, parentFolderId: nil)
        let childFolder = Folder.random(vaultId: shareId, folderId: childFolderId, parentFolderId: parentFolderId)

        let encryptedParent = SymmetricallyEncryptedFolder(
            shareId: shareId,
            userId: userId,
            folder: parentFolder,
            encryptedContent: .random()
        )
        let encryptedChild = SymmetricallyEncryptedFolder(
            shareId: shareId,
            userId: userId,
            folder: childFolder,
            encryptedContent: .random()
        )

        // When
        try await sut.upsertFolders([encryptedParent, encryptedChild], userId: userId)

        // Then
        let folders = try await sut.getAllFolders(userId: userId)
        #expect(folders.count == 2)

        let retrievedChild = try #require(folders.first(where: { $0.folderId == childFolderId }))
        #expect(retrievedChild.folder.parentFolderID == parentFolderId)

        let retrievedParent = try #require(folders.first(where: { $0.folderId == parentFolderId }))
        #expect(retrievedParent.folder.parentFolderID == nil)
    }
}

// MARK: - Helper Extension

private extension LocalFolderDatasource {
    @discardableResult
    func givenInsertedFolder(shareId: String? = nil,
                             folderId: String? = nil,
                             userId: String? = nil,
                             parentFolderId: String? = nil) async throws -> SymmetricallyEncryptedFolder {
        let shareId = shareId ?? .random()
        let userId = userId ?? .random()
        let folder = Folder.random(
            vaultId: shareId,
            folderId: folderId ?? .random(),
            parentFolderId: parentFolderId
        )
        let encryptedFolder = SymmetricallyEncryptedFolder(
            shareId: shareId,
            userId: userId,
            folder: folder,
            encryptedContent: .random()
        )
        try await upsertFolders([encryptedFolder], userId: userId)
        return encryptedFolder
    }
}
