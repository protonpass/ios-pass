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
import CoreData
import Entities

public final class LocalFolderDatasourceProtocolMock: @unchecked Sendable, LocalFolderDatasourceProtocol {

    public init() {}

    // MARK: - getAllFolders
    public var getAllFoldersUserIdThrowableError1: Error?
    public var closureGetAllFolders: () -> () = {}
    public var invokedGetAllFoldersfunction = false
    public var invokedGetAllFoldersCount = 0
    public var invokedGetAllFoldersParameters: (userId: String, Void)?
    public var invokedGetAllFoldersParametersList = [(userId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetAllFoldersResult: [SymmetricallyEncryptedFolder]!

    public func getAllFolders(userId: String) async throws -> [SymmetricallyEncryptedFolder] {
        invokedGetAllFoldersfunction = true
        invokedGetAllFoldersCount += 1
        invokedGetAllFoldersParameters = (userId, ())
        if let error = getAllFoldersUserIdThrowableError1 {
            throw error
        }
        closureGetAllFolders()
        return stubbedGetAllFoldersResult
    }
    // MARK: - getFolder
    public var getFolderShareIdFolderIdThrowableError2: Error?
    public var closureGetFolder: () -> () = {}
    public var invokedGetFolderfunction = false
    public var invokedGetFolderCount = 0
    public var invokedGetFolderParameters: (shareId: String, folderId: String)?
    public var invokedGetFolderParametersList = [(shareId: String, folderId: String)]()
    public nonisolated(unsafe) var stubbedGetFolderResult: SymmetricallyEncryptedFolder?

    public func getFolder(shareId: String, folderId: String) async throws -> SymmetricallyEncryptedFolder? {
        invokedGetFolderfunction = true
        invokedGetFolderCount += 1
        invokedGetFolderParameters = (shareId, folderId)
        if let error = getFolderShareIdFolderIdThrowableError2 {
            throw error
        }
        closureGetFolder()
        return stubbedGetFolderResult
    }
    // MARK: - upsertFolders
    public var upsertFoldersUserIdThrowableError3: Error?
    public var closureUpsertFolders: () -> () = {}
    public var invokedUpsertFoldersfunction = false
    public var invokedUpsertFoldersCount = 0
    public var invokedUpsertFoldersParameters: (folders: [SymmetricallyEncryptedFolder], userId: String)?
    public var invokedUpsertFoldersParametersList = [(folders: [SymmetricallyEncryptedFolder], userId: String)]()

    public func upsertFolders(_ folders: [SymmetricallyEncryptedFolder], userId: String) async throws {
        invokedUpsertFoldersfunction = true
        invokedUpsertFoldersCount += 1
        invokedUpsertFoldersParameters = (folders, userId)
        if let error = upsertFoldersUserIdThrowableError3 {
            throw error
        }
        closureUpsertFolders()
    }
    // MARK: - removeAllFoldersUserId
    public var removeAllFoldersUserIdThrowableError4: Error?
    public var closureRemoveAllFoldersUserIdAsync4: () -> () = {}
    public var invokedRemoveAllFoldersUserIdAsync4 = false
    public var invokedRemoveAllFoldersUserIdAsyncCount4 = 0
    public var invokedRemoveAllFoldersUserIdAsyncParameters4: (userId: String, Void)?
    public var invokedRemoveAllFoldersUserIdAsyncParametersList4 = [(userId: String, Void)]()

    public func removeAllFolders(userId: String) async throws {
        invokedRemoveAllFoldersUserIdAsync4 = true
        invokedRemoveAllFoldersUserIdAsyncCount4 += 1
        invokedRemoveAllFoldersUserIdAsyncParameters4 = (userId, ())
        if let error = removeAllFoldersUserIdThrowableError4 {
            throw error
        }
        closureRemoveAllFoldersUserIdAsync4()
    }
    // MARK: - removeAllFoldersShareId
    public var removeAllFoldersShareIdThrowableError5: Error?
    public var closureRemoveAllFoldersShareIdAsync5: () -> () = {}
    public var invokedRemoveAllFoldersShareIdAsync5 = false
    public var invokedRemoveAllFoldersShareIdAsyncCount5 = 0
    public var invokedRemoveAllFoldersShareIdAsyncParameters5: (shareId: String, Void)?
    public var invokedRemoveAllFoldersShareIdAsyncParametersList5 = [(shareId: String, Void)]()

    public func removeAllFolders(shareId: String) async throws {
        invokedRemoveAllFoldersShareIdAsync5 = true
        invokedRemoveAllFoldersShareIdAsyncCount5 += 1
        invokedRemoveAllFoldersShareIdAsyncParameters5 = (shareId, ())
        if let error = removeAllFoldersShareIdThrowableError5 {
            throw error
        }
        closureRemoveAllFoldersShareIdAsync5()
    }
    // MARK: - deleteFolders
    public var deleteFoldersUserIdFolderIdsShareIdThrowableError6: Error?
    public var closureDeleteFolders: () -> () = {}
    public var invokedDeleteFoldersfunction = false
    public var invokedDeleteFoldersCount = 0
    public var invokedDeleteFoldersParameters: (userId: String, folderIds: [String], shareId: String)?
    public var invokedDeleteFoldersParametersList = [(userId: String, folderIds: [String], shareId: String)]()

    public func deleteFolders(userId: String, folderIds: [String], shareId: String) async throws {
        invokedDeleteFoldersfunction = true
        invokedDeleteFoldersCount += 1
        invokedDeleteFoldersParameters = (userId, folderIds, shareId)
        if let error = deleteFoldersUserIdFolderIdsShareIdThrowableError6 {
            throw error
        }
        closureDeleteFolders()
    }
}
