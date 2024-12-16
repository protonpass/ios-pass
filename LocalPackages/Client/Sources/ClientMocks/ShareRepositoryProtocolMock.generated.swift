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
import Combine
import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreLogin

public final class ShareRepositoryProtocolMock: @unchecked Sendable, ShareRepositoryProtocol {

    public init() {}

    // MARK: - getShares
    public var getSharesUserIdThrowableError1: Error?
    public var closureGetShares: () -> () = {}
    public var invokedGetSharesfunction = false
    public var invokedGetSharesCount = 0
    public var invokedGetSharesParameters: (userId: String, Void)?
    public var invokedGetSharesParametersList = [(userId: String, Void)]()
    public var stubbedGetSharesResult: [SymmetricallyEncryptedShare]!

    public func getShares(userId: String) async throws -> [SymmetricallyEncryptedShare] {
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
    public var getShareShareIdThrowableError2: Error?
    public var closureGetShare: () -> () = {}
    public var invokedGetSharefunction = false
    public var invokedGetShareCount = 0
    public var invokedGetShareParameters: (shareId: String, Void)?
    public var invokedGetShareParametersList = [(shareId: String, Void)]()
    public var stubbedGetShareResult: Share?

    public func getShare(shareId: String) async throws -> Share? {
        invokedGetSharefunction = true
        invokedGetShareCount += 1
        invokedGetShareParameters = (shareId, ())
        invokedGetShareParametersList.append((shareId, ()))
        if let error = getShareShareIdThrowableError2 {
            throw error
        }
        closureGetShare()
        return stubbedGetShareResult
    }
    // MARK: - getDecryptedShares
    public var getDecryptedSharesUserIdThrowableError3: Error?
    public var closureGetDecryptedShares: () -> () = {}
    public var invokedGetDecryptedSharesfunction = false
    public var invokedGetDecryptedSharesCount = 0
    public var invokedGetDecryptedSharesParameters: (userId: String, Void)?
    public var invokedGetDecryptedSharesParametersList = [(userId: String, Void)]()
    public var stubbedGetDecryptedSharesResult: [Share]!

    public func getDecryptedShares(userId: String) async throws -> [Share] {
        invokedGetDecryptedSharesfunction = true
        invokedGetDecryptedSharesCount += 1
        invokedGetDecryptedSharesParameters = (userId, ())
        invokedGetDecryptedSharesParametersList.append((userId, ()))
        if let error = getDecryptedSharesUserIdThrowableError3 {
            throw error
        }
        closureGetDecryptedShares()
        return stubbedGetDecryptedSharesResult
    }
    // MARK: - getDecryptedShare
    public var getDecryptedShareShareIdThrowableError4: Error?
    public var closureGetDecryptedShare: () -> () = {}
    public var invokedGetDecryptedSharefunction = false
    public var invokedGetDecryptedShareCount = 0
    public var invokedGetDecryptedShareParameters: (shareId: String, Void)?
    public var invokedGetDecryptedShareParametersList = [(shareId: String, Void)]()
    public var stubbedGetDecryptedShareResult: Share?

    public func getDecryptedShare(shareId: String) async throws -> Share? {
        invokedGetDecryptedSharefunction = true
        invokedGetDecryptedShareCount += 1
        invokedGetDecryptedShareParameters = (shareId, ())
        invokedGetDecryptedShareParametersList.append((shareId, ()))
        if let error = getDecryptedShareShareIdThrowableError4 {
            throw error
        }
        closureGetDecryptedShare()
        return stubbedGetDecryptedShareResult
    }
    // MARK: - getRemoteShares
    public var getRemoteSharesUserIdThrowableError5: Error?
    public var closureGetRemoteShares: () -> () = {}
    public var invokedGetRemoteSharesfunction = false
    public var invokedGetRemoteSharesCount = 0
    public var invokedGetRemoteSharesParameters: (userId: String, Void)?
    public var invokedGetRemoteSharesParametersList = [(userId: String, Void)]()
    public var stubbedGetRemoteSharesResult: [Share]!

    public func getRemoteShares(userId: String) async throws -> [Share] {
        invokedGetRemoteSharesfunction = true
        invokedGetRemoteSharesCount += 1
        invokedGetRemoteSharesParameters = (userId, ())
        invokedGetRemoteSharesParametersList.append((userId, ()))
        if let error = getRemoteSharesUserIdThrowableError5 {
            throw error
        }
        closureGetRemoteShares()
        return stubbedGetRemoteSharesResult
    }
    // MARK: - deleteAllCurrentUserSharesLocally
    public var deleteAllCurrentUserSharesLocallyThrowableError6: Error?
    public var closureDeleteAllCurrentUserSharesLocally: () -> () = {}
    public var invokedDeleteAllCurrentUserSharesLocallyfunction = false
    public var invokedDeleteAllCurrentUserSharesLocallyCount = 0

    public func deleteAllCurrentUserSharesLocally() async throws {
        invokedDeleteAllCurrentUserSharesLocallyfunction = true
        invokedDeleteAllCurrentUserSharesLocallyCount += 1
        if let error = deleteAllCurrentUserSharesLocallyThrowableError6 {
            throw error
        }
        closureDeleteAllCurrentUserSharesLocally()
    }
    // MARK: - deleteShareLocally
    public var deleteShareLocallyUserIdShareIdThrowableError7: Error?
    public var closureDeleteShareLocally: () -> () = {}
    public var invokedDeleteShareLocallyfunction = false
    public var invokedDeleteShareLocallyCount = 0
    public var invokedDeleteShareLocallyParameters: (userId: String, shareId: String)?
    public var invokedDeleteShareLocallyParametersList = [(userId: String, shareId: String)]()

    public func deleteShareLocally(userId: String, shareId: String) async throws {
        invokedDeleteShareLocallyfunction = true
        invokedDeleteShareLocallyCount += 1
        invokedDeleteShareLocallyParameters = (userId, shareId)
        invokedDeleteShareLocallyParametersList.append((userId, shareId))
        if let error = deleteShareLocallyUserIdShareIdThrowableError7 {
            throw error
        }
        closureDeleteShareLocally()
    }
    // MARK: - upsertShares
    public var upsertSharesUserIdSharesEventStreamThrowableError8: Error?
    public var closureUpsertShares: () -> () = {}
    public var invokedUpsertSharesfunction = false
    public var invokedUpsertSharesCount = 0
    public var invokedUpsertSharesParameters: (userId: String, shares: [Share], eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?)?
    public var invokedUpsertSharesParametersList = [(userId: String, shares: [Share], eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?)]()

    public func upsertShares(userId: String, shares: [Share], eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws {
        invokedUpsertSharesfunction = true
        invokedUpsertSharesCount += 1
        invokedUpsertSharesParameters = (userId, shares, eventStream)
        invokedUpsertSharesParametersList.append((userId, shares, eventStream))
        if let error = upsertSharesUserIdSharesEventStreamThrowableError8 {
            throw error
        }
        closureUpsertShares()
    }
    // MARK: - getUsersLinkedToVaultShare
    public var getUsersLinkedToVaultShareToLastShareIdThrowableError9: Error?
    public var closureGetUsersLinkedToVaultShare: () -> () = {}
    public var invokedGetUsersLinkedToVaultSharefunction = false
    public var invokedGetUsersLinkedToVaultShareCount = 0
    public var invokedGetUsersLinkedToVaultShareParameters: (shareId: String, lastShareId: String?)?
    public var invokedGetUsersLinkedToVaultShareParametersList = [(shareId: String, lastShareId: String?)]()
    public var stubbedGetUsersLinkedToVaultShareResult: PaginatedUsersLinkedToShare!

    public func getUsersLinkedToVaultShare(to shareId: String, lastShareId: String?) async throws -> PaginatedUsersLinkedToShare {
        invokedGetUsersLinkedToVaultSharefunction = true
        invokedGetUsersLinkedToVaultShareCount += 1
        invokedGetUsersLinkedToVaultShareParameters = (shareId, lastShareId)
        invokedGetUsersLinkedToVaultShareParametersList.append((shareId, lastShareId))
        if let error = getUsersLinkedToVaultShareToLastShareIdThrowableError9 {
            throw error
        }
        closureGetUsersLinkedToVaultShare()
        return stubbedGetUsersLinkedToVaultShareResult
    }
    // MARK: - getUsersLinkedToItemShare
    public var getUsersLinkedToItemShareToItemIdLastShareIdThrowableError10: Error?
    public var closureGetUsersLinkedToItemShare: () -> () = {}
    public var invokedGetUsersLinkedToItemSharefunction = false
    public var invokedGetUsersLinkedToItemShareCount = 0
    public var invokedGetUsersLinkedToItemShareParameters: (shareId: String, itemId: String, lastShareId: String?)?
    public var invokedGetUsersLinkedToItemShareParametersList = [(shareId: String, itemId: String, lastShareId: String?)]()
    public var stubbedGetUsersLinkedToItemShareResult: PaginatedUsersLinkedToShare!

    public func getUsersLinkedToItemShare(to shareId: String, itemId: String, lastShareId: String?) async throws -> PaginatedUsersLinkedToShare {
        invokedGetUsersLinkedToItemSharefunction = true
        invokedGetUsersLinkedToItemShareCount += 1
        invokedGetUsersLinkedToItemShareParameters = (shareId, itemId, lastShareId)
        invokedGetUsersLinkedToItemShareParametersList.append((shareId, itemId, lastShareId))
        if let error = getUsersLinkedToItemShareToItemIdLastShareIdThrowableError10 {
            throw error
        }
        closureGetUsersLinkedToItemShare()
        return stubbedGetUsersLinkedToItemShareResult
    }
    // MARK: - updateUserPermission
    public var updateUserPermissionUserShareIdShareIdShareRoleExpireTimeThrowableError11: Error?
    public var closureUpdateUserPermission: () -> () = {}
    public var invokedUpdateUserPermissionfunction = false
    public var invokedUpdateUserPermissionCount = 0
    public var invokedUpdateUserPermissionParameters: (userShareId: String, shareId: String, shareRole: ShareRole?, expireTime: Int?)?
    public var invokedUpdateUserPermissionParametersList = [(userShareId: String, shareId: String, shareRole: ShareRole?, expireTime: Int?)]()
    public var stubbedUpdateUserPermissionResult: Bool!

    public func updateUserPermission(userShareId: String, shareId: String, shareRole: ShareRole?, expireTime: Int?) async throws -> Bool {
        invokedUpdateUserPermissionfunction = true
        invokedUpdateUserPermissionCount += 1
        invokedUpdateUserPermissionParameters = (userShareId, shareId, shareRole, expireTime)
        invokedUpdateUserPermissionParametersList.append((userShareId, shareId, shareRole, expireTime))
        if let error = updateUserPermissionUserShareIdShareIdShareRoleExpireTimeThrowableError11 {
            throw error
        }
        closureUpdateUserPermission()
        return stubbedUpdateUserPermissionResult
    }
    // MARK: - deleteUserShare
    public var deleteUserShareUserShareIdShareIdThrowableError12: Error?
    public var closureDeleteUserShare: () -> () = {}
    public var invokedDeleteUserSharefunction = false
    public var invokedDeleteUserShareCount = 0
    public var invokedDeleteUserShareParameters: (userShareId: String, shareId: String)?
    public var invokedDeleteUserShareParametersList = [(userShareId: String, shareId: String)]()
    public var stubbedDeleteUserShareResult: Bool!

    public func deleteUserShare(userShareId: String, shareId: String) async throws -> Bool {
        invokedDeleteUserSharefunction = true
        invokedDeleteUserShareCount += 1
        invokedDeleteUserShareParameters = (userShareId, shareId)
        invokedDeleteUserShareParametersList.append((userShareId, shareId))
        if let error = deleteUserShareUserShareIdShareIdThrowableError12 {
            throw error
        }
        closureDeleteUserShare()
        return stubbedDeleteUserShareResult
    }
    // MARK: - deleteShare
    public var deleteShareUserIdShareIdThrowableError13: Error?
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
        if let error = deleteShareUserIdShareIdThrowableError13 {
            throw error
        }
        closureDeleteShare()
        return stubbedDeleteShareResult
    }
    // MARK: - createVault
    public var createVaultThrowableError14: Error?
    public var closureCreateVault: () -> () = {}
    public var invokedCreateVaultfunction = false
    public var invokedCreateVaultCount = 0
    public var invokedCreateVaultParameters: (vault: VaultContent, Void)?
    public var invokedCreateVaultParametersList = [(vault: VaultContent, Void)]()
    public var stubbedCreateVaultResult: Share!

    public func createVault(_ vault: VaultContent) async throws -> Share {
        invokedCreateVaultfunction = true
        invokedCreateVaultCount += 1
        invokedCreateVaultParameters = (vault, ())
        invokedCreateVaultParametersList.append((vault, ()))
        if let error = createVaultThrowableError14 {
            throw error
        }
        closureCreateVault()
        return stubbedCreateVaultResult
    }
    // MARK: - edit
    public var editOldVaultNewVaultThrowableError15: Error?
    public var closureEdit: () -> () = {}
    public var invokedEditfunction = false
    public var invokedEditCount = 0
    public var invokedEditParameters: (oldVault: Share, newVault: VaultContent)?
    public var invokedEditParametersList = [(oldVault: Share, newVault: VaultContent)]()

    public func edit(oldVault: Share, newVault: VaultContent) async throws {
        invokedEditfunction = true
        invokedEditCount += 1
        invokedEditParameters = (oldVault, newVault)
        invokedEditParametersList.append((oldVault, newVault))
        if let error = editOldVaultNewVaultThrowableError15 {
            throw error
        }
        closureEdit()
    }
    // MARK: - deleteVault
    public var deleteVaultShareIdThrowableError16: Error?
    public var closureDeleteVault: () -> () = {}
    public var invokedDeleteVaultfunction = false
    public var invokedDeleteVaultCount = 0
    public var invokedDeleteVaultParameters: (shareId: String, Void)?
    public var invokedDeleteVaultParametersList = [(shareId: String, Void)]()

    public func deleteVault(shareId: String) async throws {
        invokedDeleteVaultfunction = true
        invokedDeleteVaultCount += 1
        invokedDeleteVaultParameters = (shareId, ())
        invokedDeleteVaultParametersList.append((shareId, ()))
        if let error = deleteVaultShareIdThrowableError16 {
            throw error
        }
        closureDeleteVault()
    }
    // MARK: - transferVaultOwnership
    public var transferVaultOwnershipVaultShareIdNewOwnerShareIdThrowableError17: Error?
    public var closureTransferVaultOwnership: () -> () = {}
    public var invokedTransferVaultOwnershipfunction = false
    public var invokedTransferVaultOwnershipCount = 0
    public var invokedTransferVaultOwnershipParameters: (vaultShareId: String, newOwnerShareId: String)?
    public var invokedTransferVaultOwnershipParametersList = [(vaultShareId: String, newOwnerShareId: String)]()
    public var stubbedTransferVaultOwnershipResult: Bool!

    public func transferVaultOwnership(vaultShareId: String, newOwnerShareId: String) async throws -> Bool {
        invokedTransferVaultOwnershipfunction = true
        invokedTransferVaultOwnershipCount += 1
        invokedTransferVaultOwnershipParameters = (vaultShareId, newOwnerShareId)
        invokedTransferVaultOwnershipParametersList.append((vaultShareId, newOwnerShareId))
        if let error = transferVaultOwnershipVaultShareIdNewOwnerShareIdThrowableError17 {
            throw error
        }
        closureTransferVaultOwnership()
        return stubbedTransferVaultOwnershipResult
    }
}
