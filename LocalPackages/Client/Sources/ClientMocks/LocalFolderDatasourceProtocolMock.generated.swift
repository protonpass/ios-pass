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
    // MARK: - removeAllFolders
    public var removeAllFoldersThrowableError4: Error?
    public var closureRemoveAllFoldersAsync4: () -> () = {}
    public var invokedRemoveAllFoldersAsync4 = false
    public var invokedRemoveAllFoldersAsyncCount4 = 0

    public func removeAllFolders() async throws {
        invokedRemoveAllFoldersAsync4 = true
        invokedRemoveAllFoldersAsyncCount4 += 1
        if let error = removeAllFoldersThrowableError4 {
            throw error
        }
        closureRemoveAllFoldersAsync4()
    }
    // MARK: - removeAllFoldersUserId
    public var removeAllFoldersUserIdThrowableError5: Error?
    public var closureRemoveAllFoldersUserIdAsync5: () -> () = {}
    public var invokedRemoveAllFoldersUserIdAsync5 = false
    public var invokedRemoveAllFoldersUserIdAsyncCount5 = 0
    public var invokedRemoveAllFoldersUserIdAsyncParameters5: (userId: String, Void)?
    public var invokedRemoveAllFoldersUserIdAsyncParametersList5 = [(userId: String, Void)]()

    public func removeAllFolders(userId: String) async throws {
        invokedRemoveAllFoldersUserIdAsync5 = true
        invokedRemoveAllFoldersUserIdAsyncCount5 += 1
        invokedRemoveAllFoldersUserIdAsyncParameters5 = (userId, ())
        if let error = removeAllFoldersUserIdThrowableError5 {
            throw error
        }
        closureRemoveAllFoldersUserIdAsync5()
    }
    // MARK: - removeAllFoldersShareId
    public var removeAllFoldersShareIdThrowableError6: Error?
    public var closureRemoveAllFoldersShareIdAsync6: () -> () = {}
    public var invokedRemoveAllFoldersShareIdAsync6 = false
    public var invokedRemoveAllFoldersShareIdAsyncCount6 = 0
    public var invokedRemoveAllFoldersShareIdAsyncParameters6: (shareId: String, Void)?
    public var invokedRemoveAllFoldersShareIdAsyncParametersList6 = [(shareId: String, Void)]()

    public func removeAllFolders(shareId: String) async throws {
        invokedRemoveAllFoldersShareIdAsync6 = true
        invokedRemoveAllFoldersShareIdAsyncCount6 += 1
        invokedRemoveAllFoldersShareIdAsyncParameters6 = (shareId, ())
        if let error = removeAllFoldersShareIdThrowableError6 {
            throw error
        }
        closureRemoveAllFoldersShareIdAsync6()
    }
    // MARK: - deleteFoldersUserIdFolderIdsShareId
    public var deleteFoldersUserIdFolderIdsShareIdThrowableError7: Error?
    public var closureDeleteFoldersUserIdFolderIdsShareIdAsync7: () -> () = {}
    public var invokedDeleteFoldersUserIdFolderIdsShareIdAsync7 = false
    public var invokedDeleteFoldersUserIdFolderIdsShareIdAsyncCount7 = 0
    public var invokedDeleteFoldersUserIdFolderIdsShareIdAsyncParameters7: (userId: String, folderIds: [String], shareId: String)?
    public var invokedDeleteFoldersUserIdFolderIdsShareIdAsyncParametersList7 = [(userId: String, folderIds: [String], shareId: String)]()

    public func deleteFolders(userId: String, folderIds: [String], shareId: String) async throws {
        invokedDeleteFoldersUserIdFolderIdsShareIdAsync7 = true
        invokedDeleteFoldersUserIdFolderIdsShareIdAsyncCount7 += 1
        invokedDeleteFoldersUserIdFolderIdsShareIdAsyncParameters7 = (userId, folderIds, shareId)
        if let error = deleteFoldersUserIdFolderIdsShareIdThrowableError7 {
            throw error
        }
        closureDeleteFoldersUserIdFolderIdsShareIdAsync7()
    }
    // MARK: - deleteFoldersShareIdUserId
    public var deleteFoldersShareIdUserIdThrowableError8: Error?
    public var closureDeleteFoldersShareIdUserIdAsync8: () -> () = {}
    public var invokedDeleteFoldersShareIdUserIdAsync8 = false
    public var invokedDeleteFoldersShareIdUserIdAsyncCount8 = 0
    public var invokedDeleteFoldersShareIdUserIdAsyncParameters8: (shareId: String, userId: String)?
    public var invokedDeleteFoldersShareIdUserIdAsyncParametersList8 = [(shareId: String, userId: String)]()

    public func deleteFolders(shareId: String, userId: String) async throws {
        invokedDeleteFoldersShareIdUserIdAsync8 = true
        invokedDeleteFoldersShareIdUserIdAsyncCount8 += 1
        invokedDeleteFoldersShareIdUserIdAsyncParameters8 = (shareId, userId)
        if let error = deleteFoldersShareIdUserIdThrowableError8 {
            throw error
        }
        closureDeleteFoldersShareIdUserIdAsync8()
    }
}
