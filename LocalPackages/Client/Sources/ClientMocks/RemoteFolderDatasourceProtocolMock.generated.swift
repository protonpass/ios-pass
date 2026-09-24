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
import Entities
import Foundation

public final class RemoteFolderDatasourceProtocolMock: @unchecked Sendable, RemoteFolderDatasourceProtocol {

    public init() {}

    // MARK: - getFolders
    public var getFoldersUserIdShareIdSinceTokenPageSizeThrowableError1: Error?
    public var closureGetFolders: () -> () = {}
    public var invokedGetFoldersfunction = false
    public var invokedGetFoldersCount = 0
    public var invokedGetFoldersParameters: (userId: String, shareId: String, sinceToken: String?, pageSize: Int)?
    public var invokedGetFoldersParametersList = [(userId: String, shareId: String, sinceToken: String?, pageSize: Int)]()
    public nonisolated(unsafe) var stubbedGetFoldersResult: PaginatedFolders!

    public func getFolders(userId: String, shareId: String, sinceToken: String?, pageSize: Int) async throws -> PaginatedFolders {
        invokedGetFoldersfunction = true
        invokedGetFoldersCount += 1
        invokedGetFoldersParameters = (userId, shareId, sinceToken, pageSize)
        if let error = getFoldersUserIdShareIdSinceTokenPageSizeThrowableError1 {
            throw error
        }
        closureGetFolders()
        return stubbedGetFoldersResult
    }
    // MARK: - getFolder
    public var getFolderUserIdShareIdFolderIdThrowableError2: Error?
    public var closureGetFolder: () -> () = {}
    public var invokedGetFolderfunction = false
    public var invokedGetFolderCount = 0
    public var invokedGetFolderParameters: (userId: String, shareId: String, folderId: String)?
    public var invokedGetFolderParametersList = [(userId: String, shareId: String, folderId: String)]()
    public nonisolated(unsafe) var stubbedGetFolderResult: Folder!

    public func getFolder(userId: String, shareId: String, folderId: String) async throws -> Folder {
        invokedGetFolderfunction = true
        invokedGetFolderCount += 1
        invokedGetFolderParameters = (userId, shareId, folderId)
        if let error = getFolderUserIdShareIdFolderIdThrowableError2 {
            throw error
        }
        closureGetFolder()
        return stubbedGetFolderResult
    }
    // MARK: - create
    public var createUserIdShareIdRequestThrowableError3: Error?
    public var closureCreate: () -> () = {}
    public var invokedCreatefunction = false
    public var invokedCreateCount = 0
    public var invokedCreateParameters: (userId: String, shareId: String, request: CreateFolderRequest)?
    public var invokedCreateParametersList = [(userId: String, shareId: String, request: CreateFolderRequest)]()
    public nonisolated(unsafe) var stubbedCreateResult: Folder!

    public func create(userId: String, shareId: String, request: CreateFolderRequest) async throws -> Folder {
        invokedCreatefunction = true
        invokedCreateCount += 1
        invokedCreateParameters = (userId, shareId, request)
        if let error = createUserIdShareIdRequestThrowableError3 {
            throw error
        }
        closureCreate()
        return stubbedCreateResult
    }
    // MARK: - delete
    public var deleteUserIdShareIdFolderIdsThrowableError4: Error?
    public var closureDelete: () -> () = {}
    public var invokedDeletefunction = false
    public var invokedDeleteCount = 0
    public var invokedDeleteParameters: (userId: String, shareId: String, folderIds: [String])?
    public var invokedDeleteParametersList = [(userId: String, shareId: String, folderIds: [String])]()

    public func delete(userId: String, shareId: String, folderIds: [String]) async throws {
        invokedDeletefunction = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (userId, shareId, folderIds)
        if let error = deleteUserIdShareIdFolderIdsThrowableError4 {
            throw error
        }
        closureDelete()
    }
    // MARK: - update
    public var updateUserIdShareIdFolderIdRequestThrowableError5: Error?
    public var closureUpdate: () -> () = {}
    public var invokedUpdatefunction = false
    public var invokedUpdateCount = 0
    public var invokedUpdateParameters: (userId: String, shareId: String, folderId: String, request: UpdateFolderRequest)?
    public var invokedUpdateParametersList = [(userId: String, shareId: String, folderId: String, request: UpdateFolderRequest)]()
    public nonisolated(unsafe) var stubbedUpdateResult: Folder!

    public func update(userId: String, shareId: String, folderId: String, request: UpdateFolderRequest) async throws -> Folder {
        invokedUpdatefunction = true
        invokedUpdateCount += 1
        invokedUpdateParameters = (userId, shareId, folderId, request)
        if let error = updateUserIdShareIdFolderIdRequestThrowableError5 {
            throw error
        }
        closureUpdate()
        return stubbedUpdateResult
    }
    // MARK: - move
    public var moveUserIdShareIdFolderIdRequestThrowableError6: Error?
    public var closureMove: () -> () = {}
    public var invokedMovefunction = false
    public var invokedMoveCount = 0
    public var invokedMoveParameters: (userId: String, shareId: String, folderId: String, request: MoveFolderRequest)?
    public var invokedMoveParametersList = [(userId: String, shareId: String, folderId: String, request: MoveFolderRequest)]()
    public nonisolated(unsafe) var stubbedMoveResult: Folder!

    public func move(userId: String, shareId: String, folderId: String, request: MoveFolderRequest) async throws -> Folder {
        invokedMovefunction = true
        invokedMoveCount += 1
        invokedMoveParameters = (userId, shareId, folderId, request)
        if let error = moveUserIdShareIdFolderIdRequestThrowableError6 {
            throw error
        }
        closureMove()
        return stubbedMoveResult
    }
}
