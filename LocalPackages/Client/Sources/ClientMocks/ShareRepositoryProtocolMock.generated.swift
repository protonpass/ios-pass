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
    // MARK: - getRemoteShares
    public var getRemoteSharesUserIdEventStreamThrowableError3: Error?
    public var closureGetRemoteShares: () -> () = {}
    public var invokedGetRemoteSharesfunction = false
    public var invokedGetRemoteSharesCount = 0
    public var invokedGetRemoteSharesParameters: (userId: String, eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?)?
    public var invokedGetRemoteSharesParametersList = [(userId: String, eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?)]()
    public var stubbedGetRemoteSharesResult: [Share]!

    public func getRemoteShares(userId: String, eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?) async throws -> [Share] {
        invokedGetRemoteSharesfunction = true
        invokedGetRemoteSharesCount += 1
        invokedGetRemoteSharesParameters = (userId, eventStream)
        invokedGetRemoteSharesParametersList.append((userId, eventStream))
        if let error = getRemoteSharesUserIdEventStreamThrowableError3 {
            throw error
        }
        closureGetRemoteShares()
        return stubbedGetRemoteSharesResult
    }
    // MARK: - deleteAllCurrentUserSharesLocally
    public var deleteAllCurrentUserSharesLocallyThrowableError4: Error?
    public var closureDeleteAllCurrentUserSharesLocally: () -> () = {}
    public var invokedDeleteAllCurrentUserSharesLocallyfunction = false
    public var invokedDeleteAllCurrentUserSharesLocallyCount = 0

    public func deleteAllCurrentUserSharesLocally() async throws {
        invokedDeleteAllCurrentUserSharesLocallyfunction = true
        invokedDeleteAllCurrentUserSharesLocallyCount += 1
        if let error = deleteAllCurrentUserSharesLocallyThrowableError4 {
            throw error
        }
        closureDeleteAllCurrentUserSharesLocally()
    }
    // MARK: - deleteShareLocally
    public var deleteShareLocallyUserIdShareIdThrowableError5: Error?
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
        if let error = deleteShareLocallyUserIdShareIdThrowableError5 {
            throw error
        }
        closureDeleteShareLocally()
    }
    // MARK: - upsertShares
    public var upsertSharesUserIdSharesEventStreamThrowableError6: Error?
    public var closureUpsertShares: () -> () = {}
    public var invokedUpsertSharesfunction = false
    public var invokedUpsertSharesCount = 0
    public var invokedUpsertSharesParameters: (userId: String, shares: [Share], eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?)?
    public var invokedUpsertSharesParametersList = [(userId: String, shares: [Share], eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?)]()

    public func upsertShares(userId: String, shares: [Share], eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?) async throws {
        invokedUpsertSharesfunction = true
        invokedUpsertSharesCount += 1
        invokedUpsertSharesParameters = (userId, shares, eventStream)
        invokedUpsertSharesParametersList.append((userId, shares, eventStream))
        if let error = upsertSharesUserIdSharesEventStreamThrowableError6 {
            throw error
        }
        closureUpsertShares()
    }
    // MARK: - getUsersLinked
    public var getUsersLinkedToThrowableError7: Error?
    public var closureGetUsersLinked: () -> () = {}
    public var invokedGetUsersLinkedfunction = false
    public var invokedGetUsersLinkedCount = 0
    public var invokedGetUsersLinkedParameters: (shareId: String, Void)?
    public var invokedGetUsersLinkedParametersList = [(shareId: String, Void)]()
    public var stubbedGetUsersLinkedResult: [UserShareInfos]!

    public func getUsersLinked(to shareId: String) async throws -> [UserShareInfos] {
        invokedGetUsersLinkedfunction = true
        invokedGetUsersLinkedCount += 1
        invokedGetUsersLinkedParameters = (shareId, ())
        invokedGetUsersLinkedParametersList.append((shareId, ()))
        if let error = getUsersLinkedToThrowableError7 {
            throw error
        }
        closureGetUsersLinked()
        return stubbedGetUsersLinkedResult
    }
    // MARK: - updateUserPermission
    public var updateUserPermissionUserShareIdShareIdShareRoleExpireTimeThrowableError8: Error?
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
        if let error = updateUserPermissionUserShareIdShareIdShareRoleExpireTimeThrowableError8 {
            throw error
        }
        closureUpdateUserPermission()
        return stubbedUpdateUserPermissionResult
    }
    // MARK: - deleteUserShare
    public var deleteUserShareUserShareIdShareIdThrowableError9: Error?
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
        if let error = deleteUserShareUserShareIdShareIdThrowableError9 {
            throw error
        }
        closureDeleteUserShare()
        return stubbedDeleteUserShareResult
    }
    // MARK: - deleteShare
    public var deleteShareUserIdShareIdThrowableError10: Error?
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
        if let error = deleteShareUserIdShareIdThrowableError10 {
            throw error
        }
        closureDeleteShare()
        return stubbedDeleteShareResult
    }
    // MARK: - getVaults
    public var getVaultsUserIdThrowableError11: Error?
    public var closureGetVaults: () -> () = {}
    public var invokedGetVaultsfunction = false
    public var invokedGetVaultsCount = 0
    public var invokedGetVaultsParameters: (userId: String, Void)?
    public var invokedGetVaultsParametersList = [(userId: String, Void)]()
    public var stubbedGetVaultsResult: [Share]!

    public func getVaults(userId: String) async throws -> [Share] {
        invokedGetVaultsfunction = true
        invokedGetVaultsCount += 1
        invokedGetVaultsParameters = (userId, ())
        invokedGetVaultsParametersList.append((userId, ()))
        if let error = getVaultsUserIdThrowableError11 {
            throw error
        }
        closureGetVaults()
        return stubbedGetVaultsResult
    }
    // MARK: - getVault
    public var getVaultShareIdThrowableError12: Error?
    public var closureGetVault: () -> () = {}
    public var invokedGetVaultfunction = false
    public var invokedGetVaultCount = 0
    public var invokedGetVaultParameters: (shareId: String, Void)?
    public var invokedGetVaultParametersList = [(shareId: String, Void)]()
    public var stubbedGetVaultResult: Share?

    public func getVault(shareId: String) async throws -> Share? {
        invokedGetVaultfunction = true
        invokedGetVaultCount += 1
        invokedGetVaultParameters = (shareId, ())
        invokedGetVaultParametersList.append((shareId, ()))
        if let error = getVaultShareIdThrowableError12 {
            throw error
        }
        closureGetVault()
        return stubbedGetVaultResult
    }
    // MARK: - createVault
    public var createVaultThrowableError13: Error?
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
        if let error = createVaultThrowableError13 {
            throw error
        }
        closureCreateVault()
        return stubbedCreateVaultResult
    }
    // MARK: - edit
    public var editOldVaultNewVaultThrowableError14: Error?
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
        if let error = editOldVaultNewVaultThrowableError14 {
            throw error
        }
        closureEdit()
    }
    // MARK: - deleteVault
    public var deleteVaultShareIdThrowableError15: Error?
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
        if let error = deleteVaultShareIdThrowableError15 {
            throw error
        }
        closureDeleteVault()
    }
    // MARK: - transferVaultOwnership
    public var transferVaultOwnershipVaultShareIdNewOwnerShareIdThrowableError16: Error?
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
        if let error = transferVaultOwnershipVaultShareIdNewOwnerShareIdThrowableError16 {
            throw error
        }
        closureTransferVaultOwnership()
        return stubbedTransferVaultOwnershipResult
    }
}
