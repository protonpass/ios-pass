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
    // MARK: - deleteLocalFolder
    public var deleteLocalFolderUserIdShareIdFolderIdsThrowableError3: Error?
    public var closureDeleteLocalFolder: () -> () = {}
    public var invokedDeleteLocalFolderfunction = false
    public var invokedDeleteLocalFolderCount = 0
    public var invokedDeleteLocalFolderParameters: (userId: String, shareId: String, folderIds: [String])?
    public var invokedDeleteLocalFolderParametersList = [(userId: String, shareId: String, folderIds: [String])]()

    public func deleteLocalFolder(userId: String, shareId: String, folderIds: [String]) async throws {
        invokedDeleteLocalFolderfunction = true
        invokedDeleteLocalFolderCount += 1
        invokedDeleteLocalFolderParameters = (userId, shareId, folderIds)
        if let error = deleteLocalFolderUserIdShareIdFolderIdsThrowableError3 {
            throw error
        }
        closureDeleteLocalFolder()
    }
    // MARK: - deleteLocal
    public var deleteLocalFoldersUserIdThrowableError4: Error?
    public var closureDeleteLocal: () -> () = {}
    public var invokedDeleteLocalfunction = false
    public var invokedDeleteLocalCount = 0
    public var invokedDeleteLocalParameters: (folders: [any ElementIdentifiable], userId: String)?
    public var invokedDeleteLocalParametersList = [(folders: [any ElementIdentifiable], userId: String)]()

    public func deleteLocal(folders: [any ElementIdentifiable], userId: String) async throws {
        invokedDeleteLocalfunction = true
        invokedDeleteLocalCount += 1
        invokedDeleteLocalParameters = (folders, userId)
        if let error = deleteLocalFoldersUserIdThrowableError4 {
            throw error
        }
        closureDeleteLocal()
    }
    // MARK: - refreshFoldersUserIdShareId
    public var refreshFoldersUserIdShareIdThrowableError5: Error?
    public var closureRefreshFoldersUserIdShareIdAsync5: () -> () = {}
    public var invokedRefreshFoldersUserIdShareIdAsync5 = false
    public var invokedRefreshFoldersUserIdShareIdAsyncCount5 = 0
    public var invokedRefreshFoldersUserIdShareIdAsyncParameters5: (userId: String, shareId: String)?
    public var invokedRefreshFoldersUserIdShareIdAsyncParametersList5 = [(userId: String, shareId: String)]()

    public func refreshFolders(userId: String, shareId: String) async throws {
        invokedRefreshFoldersUserIdShareIdAsync5 = true
        invokedRefreshFoldersUserIdShareIdAsyncCount5 += 1
        invokedRefreshFoldersUserIdShareIdAsyncParameters5 = (userId, shareId)
        if let error = refreshFoldersUserIdShareIdThrowableError5 {
            throw error
        }
        closureRefreshFoldersUserIdShareIdAsync5()
    }
    // MARK: - delete
    public var deleteUserIdShareIdFolderIdsThrowableError6: Error?
    public var closureDelete: () -> () = {}
    public var invokedDeletefunction = false
    public var invokedDeleteCount = 0
    public var invokedDeleteParameters: (userId: String, shareId: String, folderIds: [String])?
    public var invokedDeleteParametersList = [(userId: String, shareId: String, folderIds: [String])]()

    public func delete(userId: String, shareId: String, folderIds: [String]) async throws {
        invokedDeletefunction = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (userId, shareId, folderIds)
        if let error = deleteUserIdShareIdFolderIdsThrowableError6 {
            throw error
        }
        closureDelete()
    }
    // MARK: - createFolder
    public var createFolderUserIdShareIdParentFolderIdFolderContentThrowableError7: Error?
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
        if let error = createFolderUserIdShareIdParentFolderIdFolderContentThrowableError7 {
            throw error
        }
        closureCreateFolder()
        return stubbedCreateFolderResult
    }
    // MARK: - edit
    public var editUserIdShareIdFolderIdFolderContentThrowableError8: Error?
    public var closureEdit: () -> () = {}
    public var invokedEditfunction = false
    public var invokedEditCount = 0
    public var invokedEditParameters: (userId: String, shareId: String, folderId: String, folderContent: FolderContent)?
    public var invokedEditParametersList = [(userId: String, shareId: String, folderId: String, folderContent: FolderContent)]()

    public func edit(userId: String, shareId: String, folderId: String, folderContent: FolderContent) async throws {
        invokedEditfunction = true
        invokedEditCount += 1
        invokedEditParameters = (userId, shareId, folderId, folderContent)
        if let error = editUserIdShareIdFolderIdFolderContentThrowableError8 {
            throw error
        }
        closureEdit()
    }
    // MARK: - move
    public var moveUserIdShareIdFolderIdDestinationIdThrowableError9: Error?
    public var closureMove: () -> () = {}
    public var invokedMovefunction = false
    public var invokedMoveCount = 0
    public var invokedMoveParameters: (userId: String, shareId: String, folderId: String, destinationId: String?)?
    public var invokedMoveParametersList = [(userId: String, shareId: String, folderId: String, destinationId: String?)]()

    public func move(userId: String, shareId: String, folderId: String, destinationId: String?) async throws {
        invokedMovefunction = true
        invokedMoveCount += 1
        invokedMoveParameters = (userId, shareId, folderId, destinationId)
        if let error = moveUserIdShareIdFolderIdDestinationIdThrowableError9 {
            throw error
        }
        closureMove()
    }
    // MARK: - refreshFoldersUserIdFoldersIds
    public var refreshFoldersUserIdFoldersIdsThrowableError10: Error?
    public var closureRefreshFoldersUserIdFoldersIdsAsync10: () -> () = {}
    public var invokedRefreshFoldersUserIdFoldersIdsAsync10 = false
    public var invokedRefreshFoldersUserIdFoldersIdsAsyncCount10 = 0
    public var invokedRefreshFoldersUserIdFoldersIdsAsyncParameters10: (userId: String, foldersIds: [any ElementIdentifiable])?
    public var invokedRefreshFoldersUserIdFoldersIdsAsyncParametersList10 = [(userId: String, foldersIds: [any ElementIdentifiable])]()

    public func refreshFolders(userId: String, foldersIds: [any ElementIdentifiable]) async throws {
        invokedRefreshFoldersUserIdFoldersIdsAsync10 = true
        invokedRefreshFoldersUserIdFoldersIdsAsyncCount10 += 1
        invokedRefreshFoldersUserIdFoldersIdsAsyncParameters10 = (userId, foldersIds)
        if let error = refreshFoldersUserIdFoldersIdsThrowableError10 {
            throw error
        }
        closureRefreshFoldersUserIdFoldersIdsAsync10()
    }
}
