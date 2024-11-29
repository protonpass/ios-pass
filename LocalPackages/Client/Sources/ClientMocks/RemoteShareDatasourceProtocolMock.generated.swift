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
import Entities
import Foundation

public final class RemoteShareDatasourceProtocolMock: @unchecked Sendable, RemoteShareDatasourceProtocol {

    public init() {}

    // MARK: - getShares
    public var getSharesUserIdThrowableError1: Error?
    public var closureGetShares: () -> () = {}
    public var invokedGetSharesfunction = false
    public var invokedGetSharesCount = 0
    public var invokedGetSharesParameters: (userId: String, Void)?
    public var invokedGetSharesParametersList = [(userId: String, Void)]()
    public var stubbedGetSharesResult: [Share]!

    public func getShares(userId: String) async throws -> [Share] {
        invokedGetSharesfunction = true
        invokedGetSharesCount += 1
        invokedGetSharesParameters = (userId, ())
        invokedGetSharesParametersList.append((userId, ()))
        if let error = getSharesUserIdThrowableError1 {
            throw error
        }
        closureGetShares()
        return stubbedGetSharesResult
    }
    // MARK: - getShare
    public var getShareShareIdUserIdThrowableError2: Error?
    public var closureGetShare: () -> () = {}
    public var invokedGetSharefunction = false
    public var invokedGetShareCount = 0
    public var invokedGetShareParameters: (shareId: String, userId: String)?
    public var invokedGetShareParametersList = [(shareId: String, userId: String)]()
    public var stubbedGetShareResult: Share!

    public func getShare(shareId: String, userId: String) async throws -> Share {
        invokedGetSharefunction = true
        invokedGetShareCount += 1
        invokedGetShareParameters = (shareId, userId)
        invokedGetShareParametersList.append((shareId, userId))
        if let error = getShareShareIdUserIdThrowableError2 {
            throw error
        }
        closureGetShare()
        return stubbedGetShareResult
    }
    // MARK: - getShareLinkedUsers
    public var getShareLinkedUsersUserIdShareIdThrowableError3: Error?
    public var closureGetShareLinkedUsers: () -> () = {}
    public var invokedGetShareLinkedUsersfunction = false
    public var invokedGetShareLinkedUsersCount = 0
    public var invokedGetShareLinkedUsersParameters: (userId: String, shareId: String)?
    public var invokedGetShareLinkedUsersParametersList = [(userId: String, shareId: String)]()
    public var stubbedGetShareLinkedUsersResult: [UserShareInfos]!

    public func getShareLinkedUsers(userId: String, shareId: String) async throws -> [UserShareInfos] {
        invokedGetShareLinkedUsersfunction = true
        invokedGetShareLinkedUsersCount += 1
        invokedGetShareLinkedUsersParameters = (userId, shareId)
        invokedGetShareLinkedUsersParametersList.append((userId, shareId))
        if let error = getShareLinkedUsersUserIdShareIdThrowableError3 {
            throw error
        }
        closureGetShareLinkedUsers()
        return stubbedGetShareLinkedUsersResult
    }
    // MARK: - updateUserSharePermission
    public var updateUserSharePermissionUserIdShareIdUserShareIdRequestThrowableError4: Error?
    public var closureUpdateUserSharePermission: () -> () = {}
    public var invokedUpdateUserSharePermissionfunction = false
    public var invokedUpdateUserSharePermissionCount = 0
    public var invokedUpdateUserSharePermissionParameters: (userId: String, shareId: String, userShareId: String, request: UserSharePermissionRequest)?
    public var invokedUpdateUserSharePermissionParametersList = [(userId: String, shareId: String, userShareId: String, request: UserSharePermissionRequest)]()
    public var stubbedUpdateUserSharePermissionResult: Bool!

    public func updateUserSharePermission(userId: String, shareId: String, userShareId: String, request: UserSharePermissionRequest) async throws -> Bool {
        invokedUpdateUserSharePermissionfunction = true
        invokedUpdateUserSharePermissionCount += 1
        invokedUpdateUserSharePermissionParameters = (userId, shareId, userShareId, request)
        invokedUpdateUserSharePermissionParametersList.append((userId, shareId, userShareId, request))
        if let error = updateUserSharePermissionUserIdShareIdUserShareIdRequestThrowableError4 {
            throw error
        }
        closureUpdateUserSharePermission()
        return stubbedUpdateUserSharePermissionResult
    }
    // MARK: - deleteUserShare
    public var deleteUserShareUserIdShareIdUserShareIdThrowableError5: Error?
    public var closureDeleteUserShare: () -> () = {}
    public var invokedDeleteUserSharefunction = false
    public var invokedDeleteUserShareCount = 0
    public var invokedDeleteUserShareParameters: (userId: String, shareId: String, userShareId: String)?
    public var invokedDeleteUserShareParametersList = [(userId: String, shareId: String, userShareId: String)]()
    public var stubbedDeleteUserShareResult: Bool!

    public func deleteUserShare(userId: String, shareId: String, userShareId: String) async throws -> Bool {
        invokedDeleteUserSharefunction = true
        invokedDeleteUserShareCount += 1
        invokedDeleteUserShareParameters = (userId, shareId, userShareId)
        invokedDeleteUserShareParametersList.append((userId, shareId, userShareId))
        if let error = deleteUserShareUserIdShareIdUserShareIdThrowableError5 {
            throw error
        }
        closureDeleteUserShare()
        return stubbedDeleteUserShareResult
    }
    // MARK: - deleteShare
    public var deleteShareUserIdShareIdThrowableError6: Error?
    public var closureDeleteShare: () -> () = {}
    public var invokedDeleteSharefunction = false
    public var invokedDeleteShareCount = 0
    public var invokedDeleteShareParameters: (userId: String, shareId: String)?
    public var invokedDeleteShareParametersList = [(userId: String, shareId: String)]()
    public var stubbedDeleteShareResult: Bool!

    public func deleteShare(userId: String, shareId: String) async throws -> Bool {
        invokedDeleteSharefunction = true
        invokedDeleteShareCount += 1
        invokedDeleteShareParameters = (userId, shareId)
        invokedDeleteShareParametersList.append((userId, shareId))
        if let error = deleteShareUserIdShareIdThrowableError6 {
            throw error
        }
        closureDeleteShare()
        return stubbedDeleteShareResult
    }
    // MARK: - createVault
    public var createVaultUserIdRequestThrowableError7: Error?
    public var closureCreateVault: () -> () = {}
    public var invokedCreateVaultfunction = false
    public var invokedCreateVaultCount = 0
    public var invokedCreateVaultParameters: (userId: String, request: CreateVaultRequest)?
    public var invokedCreateVaultParametersList = [(userId: String, request: CreateVaultRequest)]()
    public var stubbedCreateVaultResult: Share!

    public func createVault(userId: String, request: CreateVaultRequest) async throws -> Share {
        invokedCreateVaultfunction = true
        invokedCreateVaultCount += 1
        invokedCreateVaultParameters = (userId, request)
        invokedCreateVaultParametersList.append((userId, request))
        if let error = createVaultUserIdRequestThrowableError7 {
            throw error
        }
        closureCreateVault()
        return stubbedCreateVaultResult
    }
    // MARK: - updateVault
    public var updateVaultUserIdRequestShareIdThrowableError8: Error?
    public var closureUpdateVault: () -> () = {}
    public var invokedUpdateVaultfunction = false
    public var invokedUpdateVaultCount = 0
    public var invokedUpdateVaultParameters: (userId: String, request: UpdateVaultRequest, shareId: String)?
    public var invokedUpdateVaultParametersList = [(userId: String, request: UpdateVaultRequest, shareId: String)]()
    public var stubbedUpdateVaultResult: Share!

    public func updateVault(userId: String, request: UpdateVaultRequest, shareId: String) async throws -> Share {
        invokedUpdateVaultfunction = true
        invokedUpdateVaultCount += 1
        invokedUpdateVaultParameters = (userId, request, shareId)
        invokedUpdateVaultParametersList.append((userId, request, shareId))
        if let error = updateVaultUserIdRequestShareIdThrowableError8 {
            throw error
        }
        closureUpdateVault()
        return stubbedUpdateVaultResult
    }
    // MARK: - deleteVault
    public var deleteVaultUserIdShareIdThrowableError9: Error?
    public var closureDeleteVault: () -> () = {}
    public var invokedDeleteVaultfunction = false
    public var invokedDeleteVaultCount = 0
    public var invokedDeleteVaultParameters: (userId: String, shareId: String)?
    public var invokedDeleteVaultParametersList = [(userId: String, shareId: String)]()

    public func deleteVault(userId: String, shareId: String) async throws {
        invokedDeleteVaultfunction = true
        invokedDeleteVaultCount += 1
        invokedDeleteVaultParameters = (userId, shareId)
        invokedDeleteVaultParametersList.append((userId, shareId))
        if let error = deleteVaultUserIdShareIdThrowableError9 {
            throw error
        }
        closureDeleteVault()
    }
    // MARK: - transferVaultOwnership
    public var transferVaultOwnershipUserIdVaultShareIdRequestThrowableError10: Error?
    public var closureTransferVaultOwnership: () -> () = {}
    public var invokedTransferVaultOwnershipfunction = false
    public var invokedTransferVaultOwnershipCount = 0
    public var invokedTransferVaultOwnershipParameters: (userId: String, vaultShareId: String, request: TransferOwnershipVaultRequest)?
    public var invokedTransferVaultOwnershipParametersList = [(userId: String, vaultShareId: String, request: TransferOwnershipVaultRequest)]()
    public var stubbedTransferVaultOwnershipResult: Bool!

    public func transferVaultOwnership(userId: String, vaultShareId: String, request: TransferOwnershipVaultRequest) async throws -> Bool {
        invokedTransferVaultOwnershipfunction = true
        invokedTransferVaultOwnershipCount += 1
        invokedTransferVaultOwnershipParameters = (userId, vaultShareId, request)
        invokedTransferVaultOwnershipParametersList.append((userId, vaultShareId, request))
        if let error = transferVaultOwnershipUserIdVaultShareIdRequestThrowableError10 {
            throw error
        }
        closureTransferVaultOwnership()
        return stubbedTransferVaultOwnershipResult
    }
}
