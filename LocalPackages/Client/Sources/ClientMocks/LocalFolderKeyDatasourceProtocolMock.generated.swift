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
import Foundation

public final class LocalFolderKeyDatasourceProtocolMock: @unchecked Sendable, LocalFolderKeyDatasourceProtocol {

    public init() {}

    // MARK: - getAllFolderKeys
    public var getAllFolderKeysThrowableError1: Error?
    public var closureGetAllFolderKeysAsync1: () -> () = {}
    public var invokedGetAllFolderKeysAsync1 = false
    public var invokedGetAllFolderKeysAsyncCount1 = 0
    public var stubbedGetAllFolderKeysAsyncResult1: [SymmetricallyEncryptedFolderKey]!

    public func getAllFolderKeys() async throws -> [SymmetricallyEncryptedFolderKey] {
        invokedGetAllFolderKeysAsync1 = true
        invokedGetAllFolderKeysAsyncCount1 += 1
        if let error = getAllFolderKeysThrowableError1 {
            throw error
        }
        closureGetAllFolderKeysAsync1()
        return stubbedGetAllFolderKeysAsyncResult1
    }
    // MARK: - getAllFolderKeysUserId
    public var getAllFolderKeysUserIdThrowableError2: Error?
    public var closureGetAllFolderKeysUserIdAsync2: () -> () = {}
    public var invokedGetAllFolderKeysUserIdAsync2 = false
    public var invokedGetAllFolderKeysUserIdAsyncCount2 = 0
    public var invokedGetAllFolderKeysUserIdAsyncParameters2: (userId: String, Void)?
    public var invokedGetAllFolderKeysUserIdAsyncParametersList2 = [(userId: String, Void)]()
    public var stubbedGetAllFolderKeysUserIdAsyncResult2: [SymmetricallyEncryptedFolderKey]!

    public func getAllFolderKeys(userId: String) async throws -> [SymmetricallyEncryptedFolderKey] {
        invokedGetAllFolderKeysUserIdAsync2 = true
        invokedGetAllFolderKeysUserIdAsyncCount2 += 1
        invokedGetAllFolderKeysUserIdAsyncParameters2 = (userId, ())
        if let error = getAllFolderKeysUserIdThrowableError2 {
            throw error
        }
        closureGetAllFolderKeysUserIdAsync2()
        return stubbedGetAllFolderKeysUserIdAsyncResult2
    }
    // MARK: - upsertFolderKeys
    public var upsertFolderKeysThrowableError3: Error?
    public var closureUpsertFolderKeys: () -> () = {}
    public var invokedUpsertFolderKeysfunction = false
    public var invokedUpsertFolderKeysCount = 0
    public var invokedUpsertFolderKeysParameters: (keys: [SymmetricallyEncryptedFolderKey], Void)?
    public var invokedUpsertFolderKeysParametersList = [(keys: [SymmetricallyEncryptedFolderKey], Void)]()

    public func upsertFolderKeys(_ keys: [SymmetricallyEncryptedFolderKey]) async throws {
        invokedUpsertFolderKeysfunction = true
        invokedUpsertFolderKeysCount += 1
        invokedUpsertFolderKeysParameters = (keys, ())
        if let error = upsertFolderKeysThrowableError3 {
            throw error
        }
        closureUpsertFolderKeys()
    }
    // MARK: - removeAllKeys
    public var removeAllKeysUserIdThrowableError4: Error?
    public var closureRemoveAllKeys: () -> () = {}
    public var invokedRemoveAllKeysfunction = false
    public var invokedRemoveAllKeysCount = 0
    public var invokedRemoveAllKeysParameters: (userId: String, Void)?
    public var invokedRemoveAllKeysParametersList = [(userId: String, Void)]()

    public func removeAllKeys(userId: String) async throws {
        invokedRemoveAllKeysfunction = true
        invokedRemoveAllKeysCount += 1
        invokedRemoveAllKeysParameters = (userId, ())
        if let error = removeAllKeysUserIdThrowableError4 {
            throw error
        }
        closureRemoveAllKeys()
    }
}
