// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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
import CoreData
import CryptoKit
import Entities
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreServices

public final class ShareRepositoryProtocolMock: @unchecked Sendable, ShareRepositoryProtocol {

    public init() {}

    // MARK: - getShares
    public var getSharesThrowableError1: Error?
    public var closureGetShares: () -> () = {}
    public var invokedGetSharesfunction = false
    public var invokedGetSharesCount = 0
    public var stubbedGetSharesResult: [SymmetricallyEncryptedShare]!

    public func getShares() async throws -> [SymmetricallyEncryptedShare] {
        invokedGetSharesfunction = true
        invokedGetSharesCount += 1
        if let error = getSharesThrowableError1 {
            throw error
        }
        closureGetShares()
        return stubbedGetSharesResult
    }
    // MARK: - getRemoteShares
    public var getRemoteSharesUpdateEventStreamThrowableError2: Error?
    public var closureGetRemoteShares: () -> () = {}
    public var invokedGetRemoteSharesfunction = false
    public var invokedGetRemoteSharesCount = 0
    public var invokedGetRemoteSharesParameters: (updateEventStream: Bool, Void)?
    public var invokedGetRemoteSharesParametersList = [(updateEventStream: Bool, Void)]()
    public var stubbedGetRemoteSharesResult: [Share]!

    public func getRemoteShares(updateEventStream: Bool) async throws -> [Share] {
        invokedGetRemoteSharesfunction = true
        invokedGetRemoteSharesCount += 1
        invokedGetRemoteSharesParameters = (updateEventStream, ())
        invokedGetRemoteSharesParametersList.append((updateEventStream, ()))
        if let error = getRemoteSharesUpdateEventStreamThrowableError2 {
            throw error
        }
        closureGetRemoteShares()
        return stubbedGetRemoteSharesResult
    }
    // MARK: - deleteAllSharesLocally
    public var deleteAllSharesLocallyThrowableError3: Error?
    public var closureDeleteAllSharesLocally: () -> () = {}
    public var invokedDeleteAllSharesLocallyfunction = false
    public var invokedDeleteAllSharesLocallyCount = 0

    public func deleteAllSharesLocally() async throws {
        invokedDeleteAllSharesLocallyfunction = true
        invokedDeleteAllSharesLocallyCount += 1
        if let error = deleteAllSharesLocallyThrowableError3 {
            throw error
        }
        closureDeleteAllSharesLocally()
    }
    // MARK: - deleteShareLocally
    public var deleteShareLocallyShareIdThrowableError4: Error?
    public var closureDeleteShareLocally: () -> () = {}
    public var invokedDeleteShareLocallyfunction = false
    public var invokedDeleteShareLocallyCount = 0
    public var invokedDeleteShareLocallyParameters: (shareId: String, Void)?
    public var invokedDeleteShareLocallyParametersList = [(shareId: String, Void)]()

    public func deleteShareLocally(shareId: String) async throws {
        invokedDeleteShareLocallyfunction = true
        invokedDeleteShareLocallyCount += 1
        invokedDeleteShareLocallyParameters = (shareId, ())
        invokedDeleteShareLocallyParametersList.append((shareId, ()))
        if let error = deleteShareLocallyShareIdThrowableError4 {
            throw error
        }
        closureDeleteShareLocally()
    }
    // MARK: - upsertShares
    public var upsertSharesUpdateEventStreamThrowableError5: Error?
    public var closureUpsertShares: () -> () = {}
    public var invokedUpsertSharesfunction = false
    public var invokedUpsertSharesCount = 0
    public var invokedUpsertSharesParameters: (shares: [Share], updateEventStream: Bool)?
    public var invokedUpsertSharesParametersList = [(shares: [Share], updateEventStream: Bool)]()

    public func upsertShares(_ shares: [Share], updateEventStream: Bool) async throws {
        invokedUpsertSharesfunction = true
        invokedUpsertSharesCount += 1
        invokedUpsertSharesParameters = (shares, updateEventStream)
        invokedUpsertSharesParametersList.append((shares, updateEventStream))
        if let error = upsertSharesUpdateEventStreamThrowableError5 {
            throw error
        }
        closureUpsertShares()
    }
    // MARK: - getUsersLinked
    public var getUsersLinkedToThrowableError6: Error?
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
        if let error = getUsersLinkedToThrowableError6 {
            throw error
        }
        closureGetUsersLinked()
        return stubbedGetUsersLinkedResult
    }
    // MARK: - getUserInformations
    public var getUserInformationsUserIdShareIdThrowableError7: Error?
    public var closureGetUserInformations: () -> () = {}
    public var invokedGetUserInformationsfunction = false
    public var invokedGetUserInformationsCount = 0
    public var invokedGetUserInformationsParameters: (userId: String, shareId: String)?
    public var invokedGetUserInformationsParametersList = [(userId: String, shareId: String)]()
    public var stubbedGetUserInformationsResult: UserShareInfos!

    public func getUserInformations(userId: String, shareId: String) async throws -> UserShareInfos {
        invokedGetUserInformationsfunction = true
        invokedGetUserInformationsCount += 1
        invokedGetUserInformationsParameters = (userId, shareId)
        invokedGetUserInformationsParametersList.append((userId, shareId))
        if let error = getUserInformationsUserIdShareIdThrowableError7 {
            throw error
        }
        closureGetUserInformations()
        return stubbedGetUserInformationsResult
    }
    // MARK: - updateUserPermission
    public var updateUserPermissionUserIdShareIdShareRoleExpireTimeThrowableError8: Error?
    public var closureUpdateUserPermission: () -> () = {}
    public var invokedUpdateUserPermissionfunction = false
    public var invokedUpdateUserPermissionCount = 0
    public var invokedUpdateUserPermissionParameters: (userId: String, shareId: String, shareRole: ShareRole?, expireTime: Int?)?
    public var invokedUpdateUserPermissionParametersList = [(userId: String, shareId: String, shareRole: ShareRole?, expireTime: Int?)]()
    public var stubbedUpdateUserPermissionResult: Bool!

    public func updateUserPermission(userId: String, shareId: String, shareRole: ShareRole?, expireTime: Int?) async throws -> Bool {
        invokedUpdateUserPermissionfunction = true
        invokedUpdateUserPermissionCount += 1
        invokedUpdateUserPermissionParameters = (userId, shareId, shareRole, expireTime)
        invokedUpdateUserPermissionParametersList.append((userId, shareId, shareRole, expireTime))
        if let error = updateUserPermissionUserIdShareIdShareRoleExpireTimeThrowableError8 {
            throw error
        }
        closureUpdateUserPermission()
        return stubbedUpdateUserPermissionResult
    }
    // MARK: - deleteUserShare
    public var deleteUserShareUserIdShareIdThrowableError9: Error?
    public var closureDeleteUserShare: () -> () = {}
    public var invokedDeleteUserSharefunction = false
    public var invokedDeleteUserShareCount = 0
    public var invokedDeleteUserShareParameters: (userId: String, shareId: String)?
    public var invokedDeleteUserShareParametersList = [(userId: String, shareId: String)]()
    public var stubbedDeleteUserShareResult: Bool!

    public func deleteUserShare(userId: String, shareId: String) async throws -> Bool {
        invokedDeleteUserSharefunction = true
        invokedDeleteUserShareCount += 1
        invokedDeleteUserShareParameters = (userId, shareId)
        invokedDeleteUserShareParametersList.append((userId, shareId))
        if let error = deleteUserShareUserIdShareIdThrowableError9 {
            throw error
        }
        closureDeleteUserShare()
        return stubbedDeleteUserShareResult
    }
    // MARK: - deleteShare
    public var deleteShareShareIdThrowableError10: Error?
    public var closureDeleteShare: () -> () = {}
    public var invokedDeleteSharefunction = false
    public var invokedDeleteShareCount = 0
    public var invokedDeleteShareParameters: (shareId: String, Void)?
    public var invokedDeleteShareParametersList = [(shareId: String, Void)]()
    public var stubbedDeleteShareResult: Bool!

    public func deleteShare(shareId: String) async throws -> Bool {
        invokedDeleteSharefunction = true
        invokedDeleteShareCount += 1
        invokedDeleteShareParameters = (shareId, ())
        invokedDeleteShareParametersList.append((shareId, ()))
        if let error = deleteShareShareIdThrowableError10 {
            throw error
        }
        closureDeleteShare()
        return stubbedDeleteShareResult
    }
    // MARK: - getVaults
    public var getVaultsThrowableError11: Error?
    public var closureGetVaults: () -> () = {}
    public var invokedGetVaultsfunction = false
    public var invokedGetVaultsCount = 0
    public var stubbedGetVaultsResult: [Vault]!

    public func getVaults() async throws -> [Vault] {
        invokedGetVaultsfunction = true
        invokedGetVaultsCount += 1
        if let error = getVaultsThrowableError11 {
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
    public var stubbedGetVaultResult: Vault?

    public func getVault(shareId: String) async throws -> Vault? {
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
    public var invokedCreateVaultParameters: (vault: VaultProtobuf, Void)?
    public var invokedCreateVaultParametersList = [(vault: VaultProtobuf, Void)]()
    public var stubbedCreateVaultResult: Share!

    public func createVault(_ vault: VaultProtobuf) async throws -> Share {
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
    public var invokedEditParameters: (oldVault: Vault, newVault: VaultProtobuf)?
    public var invokedEditParametersList = [(oldVault: Vault, newVault: VaultProtobuf)]()

    public func edit(oldVault: Vault, newVault: VaultProtobuf) async throws {
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
