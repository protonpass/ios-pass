// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
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

public final class LocalShareDatasourceProtocolMock: @unchecked Sendable, LocalShareDatasourceProtocol {

    public init() {}

    // MARK: - getShare
    public var getShareUserIdShareIdThrowableError1: Error?
    public var closureGetShare: () -> () = {}
    public var invokedGetSharefunction = false
    public var invokedGetShareCount = 0
    public var invokedGetShareParameters: (userId: String, shareId: String)?
    public var invokedGetShareParametersList = [(userId: String, shareId: String)]()
    public var stubbedGetShareResult: SymmetricallyEncryptedShare?

    public func getShare(userId: String, shareId: String) async throws -> SymmetricallyEncryptedShare? {
        invokedGetSharefunction = true
        invokedGetShareCount += 1
        invokedGetShareParameters = (userId, shareId)
        invokedGetShareParametersList.append((userId, shareId))
        if let error = getShareUserIdShareIdThrowableError1 {
            throw error
        }
        closureGetShare()
        return stubbedGetShareResult
    }
    // MARK: - getAllSharesUserId
    public var getAllSharesUserIdThrowableError2: Error?
    public var closureGetAllSharesUserIdAsync2: () -> () = {}
    public var invokedGetAllSharesUserIdAsync2 = false
    public var invokedGetAllSharesUserIdAsyncCount2 = 0
    public var invokedGetAllSharesUserIdAsyncParameters2: (userId: String, Void)?
    public var invokedGetAllSharesUserIdAsyncParametersList2 = [(userId: String, Void)]()
    public var stubbedGetAllSharesUserIdAsyncResult2: [SymmetricallyEncryptedShare]!

    public func getAllShares(userId: String) async throws -> [SymmetricallyEncryptedShare] {
        invokedGetAllSharesUserIdAsync2 = true
        invokedGetAllSharesUserIdAsyncCount2 += 1
        invokedGetAllSharesUserIdAsyncParameters2 = (userId, ())
        invokedGetAllSharesUserIdAsyncParametersList2.append((userId, ()))
        if let error = getAllSharesUserIdThrowableError2 {
            throw error
        }
        closureGetAllSharesUserIdAsync2()
        return stubbedGetAllSharesUserIdAsyncResult2
    }
    // MARK: - getAllSharesVaultId
    public var getAllSharesVaultIdThrowableError3: Error?
    public var closureGetAllSharesVaultIdAsync3: () -> () = {}
    public var invokedGetAllSharesVaultIdAsync3 = false
    public var invokedGetAllSharesVaultIdAsyncCount3 = 0
    public var invokedGetAllSharesVaultIdAsyncParameters3: (vaultId: String, Void)?
    public var invokedGetAllSharesVaultIdAsyncParametersList3 = [(vaultId: String, Void)]()
    public var stubbedGetAllSharesVaultIdAsyncResult3: [SymmetricallyEncryptedShare]!

    public func getAllShares(vaultId: String) async throws -> [SymmetricallyEncryptedShare] {
        invokedGetAllSharesVaultIdAsync3 = true
        invokedGetAllSharesVaultIdAsyncCount3 += 1
        invokedGetAllSharesVaultIdAsyncParameters3 = (vaultId, ())
        invokedGetAllSharesVaultIdAsyncParametersList3.append((vaultId, ()))
        if let error = getAllSharesVaultIdThrowableError3 {
            throw error
        }
        closureGetAllSharesVaultIdAsync3()
        return stubbedGetAllSharesVaultIdAsyncResult3
    }
    // MARK: - upsertShares
    public var upsertSharesUserIdThrowableError4: Error?
    public var closureUpsertShares: () -> () = {}
    public var invokedUpsertSharesfunction = false
    public var invokedUpsertSharesCount = 0
    public var invokedUpsertSharesParameters: (shares: [SymmetricallyEncryptedShare], userId: String)?
    public var invokedUpsertSharesParametersList = [(shares: [SymmetricallyEncryptedShare], userId: String)]()

    public func upsertShares(_ shares: [SymmetricallyEncryptedShare], userId: String) async throws {
        invokedUpsertSharesfunction = true
        invokedUpsertSharesCount += 1
        invokedUpsertSharesParameters = (shares, userId)
        invokedUpsertSharesParametersList.append((shares, userId))
        if let error = upsertSharesUserIdThrowableError4 {
            throw error
        }
        closureUpsertShares()
    }
    // MARK: - removeShare
    public var removeShareShareIdUserIdThrowableError5: Error?
    public var closureRemoveShare: () -> () = {}
    public var invokedRemoveSharefunction = false
    public var invokedRemoveShareCount = 0
    public var invokedRemoveShareParameters: (shareId: String, userId: String)?
    public var invokedRemoveShareParametersList = [(shareId: String, userId: String)]()

    public func removeShare(shareId: String, userId: String) async throws {
        invokedRemoveSharefunction = true
        invokedRemoveShareCount += 1
        invokedRemoveShareParameters = (shareId, userId)
        invokedRemoveShareParametersList.append((shareId, userId))
        if let error = removeShareShareIdUserIdThrowableError5 {
            throw error
        }
        closureRemoveShare()
    }
    // MARK: - removeAllShares
    public var removeAllSharesUserIdThrowableError6: Error?
    public var closureRemoveAllShares: () -> () = {}
    public var invokedRemoveAllSharesfunction = false
    public var invokedRemoveAllSharesCount = 0
    public var invokedRemoveAllSharesParameters: (userId: String, Void)?
    public var invokedRemoveAllSharesParametersList = [(userId: String, Void)]()

    public func removeAllShares(userId: String) async throws {
        invokedRemoveAllSharesfunction = true
        invokedRemoveAllSharesCount += 1
        invokedRemoveAllSharesParameters = (userId, ())
        invokedRemoveAllSharesParametersList.append((userId, ()))
        if let error = removeAllSharesUserIdThrowableError6 {
            throw error
        }
        closureRemoveAllShares()
    }
}
