// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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

import Client
import Core
import CryptoKit
import Entities
import Foundation

public final class FolderRepositoryProtocolMock: @unchecked Sendable, FolderRepositoryProtocol {

    public init() {}

    // MARK: - getAllLocalFolders
    public var getAllLocalFoldersUserIdThrowableError1: Error?
    public var closureGetAllLocalFolders: () -> () = {}
    public var invokedGetAllLocalFoldersfunction = false
    public var invokedGetAllLocalFoldersCount = 0
    public var invokedGetAllLocalFoldersParameters: (userId: String, Void)?
    public var invokedGetAllLocalFoldersParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetAllLocalFoldersResult: [SymmetricallyEncryptedFolder]!

    public func getAllLocalFolders(userId: String) async throws -> [SymmetricallyEncryptedFolder] {
        invokedGetAllLocalFoldersfunction = true
        invokedGetAllLocalFoldersCount += 1
        invokedGetAllLocalFoldersParameters = (userId, ())
        if let error = getAllLocalFoldersUserIdThrowableError1 {
            throw error
        }
        closureGetAllLocalFolders()
        return stubbedGetAllLocalFoldersResult
    }
    // MARK: - deleteAllLocalFolders
    public var deleteAllLocalFoldersUserIdThrowableError2: Error?
    public var closureDeleteAllLocalFolders: () -> () = {}
    public var invokedDeleteAllLocalFoldersfunction = false
    public var invokedDeleteAllLocalFoldersCount = 0
    public var invokedDeleteAllLocalFoldersParameters: (userId: String, Void)?
    public var invokedDeleteAllLocalFoldersParametersList = [(userId: String, Void)]()

    public func deleteAllLocalFolders(userId: String) async throws {
        invokedDeleteAllLocalFoldersfunction = true
        invokedDeleteAllLocalFoldersCount += 1
        invokedDeleteAllLocalFoldersParameters = (userId, ())
        if let error = deleteAllLocalFoldersUserIdThrowableError2 {
            throw error
        }
        closureDeleteAllLocalFolders()
    }
    // MARK: - deleteLocalFolders
    public var deleteLocalFoldersUserIdShareIdFolderIdsThrowableError3: Error?
    public var closureDeleteLocalFolders: () -> () = {}
    public var invokedDeleteLocalFoldersfunction = false
    public var invokedDeleteLocalFoldersCount = 0
    public var invokedDeleteLocalFoldersParameters: (userId: String, shareId: String, folderIds: [String])?
    public var invokedDeleteLocalFoldersParametersList = [(userId: String, shareId: String, folderIds: [String])]()

    public func deleteLocalFolders(userId: String, shareId: String, folderIds: [String]) async throws {
        invokedDeleteLocalFoldersfunction = true
        invokedDeleteLocalFoldersCount += 1
        invokedDeleteLocalFoldersParameters = (userId, shareId, folderIds)
        if let error = deleteLocalFoldersUserIdShareIdFolderIdsThrowableError3 {
            throw error
        }
        closureDeleteLocalFolders()
    }
    // MARK: - deleteLocal
    public var deleteLocalFoldersUserIdThrowableError4: Error?
    public var closureDeleteLocal: () -> () = {}
    public var invokedDeleteLocalfunction = false
    public var invokedDeleteLocalCount = 0
    public var invokedDeleteLocalParameters: (folders: [any FolderIdentifiable], userId: String)?
    public var invokedDeleteLocalParametersList = [(folders: [any FolderIdentifiable], userId: String)]()

    public func deleteLocal(folders: [any FolderIdentifiable], userId: String) async throws {
        invokedDeleteLocalfunction = true
        invokedDeleteLocalCount += 1
        invokedDeleteLocalParameters = (folders, userId)
        if let error = deleteLocalFoldersUserIdThrowableError4 {
            throw error
        }
        closureDeleteLocal()
    }
    // MARK: - deleteAllFoldersLocally
    public var deleteAllFoldersLocallyShareIdUserIdThrowableError5: Error?
    public var closureDeleteAllFoldersLocally: () -> () = {}
    public var invokedDeleteAllFoldersLocallyfunction = false
    public var invokedDeleteAllFoldersLocallyCount = 0
    public var invokedDeleteAllFoldersLocallyParameters: (shareId: String, userId: String)?
    public var invokedDeleteAllFoldersLocallyParametersList = [(shareId: String, userId: String)]()

    public func deleteAllFoldersLocally(shareId: String, userId: String) async throws {
        invokedDeleteAllFoldersLocallyfunction = true
        invokedDeleteAllFoldersLocallyCount += 1
        invokedDeleteAllFoldersLocallyParameters = (shareId, userId)
        if let error = deleteAllFoldersLocallyShareIdUserIdThrowableError5 {
            throw error
        }
        closureDeleteAllFoldersLocally()
    }
    // MARK: - refreshFoldersUserIdShareId
    public var refreshFoldersUserIdShareIdThrowableError6: Error?
    public var closureRefreshFoldersUserIdShareIdAsync6: () -> () = {}
    public var invokedRefreshFoldersUserIdShareIdAsync6 = false
    public var invokedRefreshFoldersUserIdShareIdAsyncCount6 = 0
    public var invokedRefreshFoldersUserIdShareIdAsyncParameters6: (userId: String, shareId: String)?
    public var invokedRefreshFoldersUserIdShareIdAsyncParametersList6 = [(userId: String, shareId: String)]()

    public func refreshFolders(userId: String, shareId: String) async throws {
        invokedRefreshFoldersUserIdShareIdAsync6 = true
        invokedRefreshFoldersUserIdShareIdAsyncCount6 += 1
        invokedRefreshFoldersUserIdShareIdAsyncParameters6 = (userId, shareId)
        if let error = refreshFoldersUserIdShareIdThrowableError6 {
            throw error
        }
        closureRefreshFoldersUserIdShareIdAsync6()
    }
    // MARK: - delete
    public var deleteUserIdShareIdFolderIdsThrowableError7: Error?
    public var closureDelete: () -> () = {}
    public var invokedDeletefunction = false
    public var invokedDeleteCount = 0
    public var invokedDeleteParameters: (userId: String, shareId: String, folderIds: [String])?
    public var invokedDeleteParametersList = [(userId: String, shareId: String, folderIds: [String])]()

    public func delete(userId: String, shareId: String, folderIds: [String]) async throws {
        invokedDeletefunction = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (userId, shareId, folderIds)
        if let error = deleteUserIdShareIdFolderIdsThrowableError7 {
            throw error
        }
        closureDelete()
    }
    // MARK: - createFolder
    public var createFolderUserIdShareIdParentFolderIdFolderContentThrowableError8: Error?
    public var closureCreateFolder: () -> () = {}
    public var invokedCreateFolderfunction = false
    public var invokedCreateFolderCount = 0
    public var invokedCreateFolderParameters: (userId: String, shareId: String, parentFolderId: String?, folderContent: FolderContent)?
    public var invokedCreateFolderParametersList = [(userId: String, shareId: String, parentFolderId: String?, folderContent: FolderContent)]()
    public nonisolated(unsafe) var stubbedCreateFolderResult: Folder!

    public func createFolder(userId: String, shareId: String, parentFolderId: String?, folderContent: FolderContent) async throws -> Folder {
        invokedCreateFolderfunction = true
        invokedCreateFolderCount += 1
        invokedCreateFolderParameters = (userId, shareId, parentFolderId, folderContent)
        if let error = createFolderUserIdShareIdParentFolderIdFolderContentThrowableError8 {
            throw error
        }
        closureCreateFolder()
        return stubbedCreateFolderResult
    }
    // MARK: - edit
    public var editUserIdShareIdFolderIdFolderContentThrowableError9: Error?
    public var closureEdit: () -> () = {}
    public var invokedEditfunction = false
    public var invokedEditCount = 0
    public var invokedEditParameters: (userId: String, shareId: String, folderId: String, folderContent: FolderContent)?
    public var invokedEditParametersList = [(userId: String, shareId: String, folderId: String, folderContent: FolderContent)]()

    public func edit(userId: String, shareId: String, folderId: String, folderContent: FolderContent) async throws {
        invokedEditfunction = true
        invokedEditCount += 1
        invokedEditParameters = (userId, shareId, folderId, folderContent)
        if let error = editUserIdShareIdFolderIdFolderContentThrowableError9 {
            throw error
        }
        closureEdit()
    }
    // MARK: - move
    public var moveUserIdShareIdFolderIdDestinationIdThrowableError10: Error?
    public var closureMove: () -> () = {}
    public var invokedMovefunction = false
    public var invokedMoveCount = 0
    public var invokedMoveParameters: (userId: String, shareId: String, folderId: String, destinationId: String?)?
    public var invokedMoveParametersList = [(userId: String, shareId: String, folderId: String, destinationId: String?)]()

    public func move(userId: String, shareId: String, folderId: String, destinationId: String?) async throws {
        invokedMovefunction = true
        invokedMoveCount += 1
        invokedMoveParameters = (userId, shareId, folderId, destinationId)
        if let error = moveUserIdShareIdFolderIdDestinationIdThrowableError10 {
            throw error
        }
        closureMove()
    }
    // MARK: - refreshFoldersUserIdFoldersIds
    public var refreshFoldersUserIdFoldersIdsThrowableError11: Error?
    public var closureRefreshFoldersUserIdFoldersIdsAsync11: () -> () = {}
    public var invokedRefreshFoldersUserIdFoldersIdsAsync11 = false
    public var invokedRefreshFoldersUserIdFoldersIdsAsyncCount11 = 0
    public var invokedRefreshFoldersUserIdFoldersIdsAsyncParameters11: (userId: String, foldersIds: [any FolderIdentifiable])?
    public var invokedRefreshFoldersUserIdFoldersIdsAsyncParametersList11 = [(userId: String, foldersIds: [any FolderIdentifiable])]()

    public func refreshFolders(userId: String, foldersIds: [any FolderIdentifiable]) async throws {
        invokedRefreshFoldersUserIdFoldersIdsAsync11 = true
        invokedRefreshFoldersUserIdFoldersIdsAsyncCount11 += 1
        invokedRefreshFoldersUserIdFoldersIdsAsyncParameters11 = (userId, foldersIds)
        if let error = refreshFoldersUserIdFoldersIdsThrowableError11 {
            throw error
        }
        closureRefreshFoldersUserIdFoldersIdsAsync11()
    }
}
