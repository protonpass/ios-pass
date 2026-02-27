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
import Combine
import Entities

@MainActor
public final class AppContentManagerProtocolMock: @unchecked Sendable, AppContentManagerProtocol {

    public init() {}

    // MARK: - currentShares
    public var invokedCurrentSharesSetter = false
    public var invokedCurrentSharesSetterCount = 0
    public var invokedCurrentShares: CurrentValueSubject<[Share], Never>?
    public var invokedCurrentSharesList = [CurrentValueSubject<[Share], Never>?]()
    public var invokedCurrentSharesGetter = false
    public var invokedCurrentSharesGetterCount = 0
    public nonisolated(unsafe) var stubbedCurrentShares: CurrentValueSubject<[Share], Never>!

    public var currentShares: CurrentValueSubject<[Share], Never> {
         get {
            return stubbedCurrentShares
        }
    }
    // MARK: - hasOnlyOneOwnedVault
    public var invokedHasOnlyOneOwnedVaultSetter = false
    public var invokedHasOnlyOneOwnedVaultSetterCount = 0
    public var invokedHasOnlyOneOwnedVault: Bool?
    public var invokedHasOnlyOneOwnedVaultList = [Bool?]()
    public var invokedHasOnlyOneOwnedVaultGetter = false
    public var invokedHasOnlyOneOwnedVaultGetterCount = 0
    public var stubbedHasOnlyOneOwnedVault: Bool!

    public var hasOnlyOneOwnedVault: Bool {
        set {
            invokedHasOnlyOneOwnedVaultSetter = true
            invokedHasOnlyOneOwnedVaultSetterCount += 1
            invokedHasOnlyOneOwnedVault = newValue
            invokedHasOnlyOneOwnedVaultList.append(newValue)
        } get {
            invokedHasOnlyOneOwnedVaultGetter = true
            invokedHasOnlyOneOwnedVaultGetterCount += 1
            return stubbedHasOnlyOneOwnedVault
        }
    }
    // MARK: - select
    public var closureSelect: () -> () = {}
    public var invokedSelectfunction = false
    public var invokedSelectCount = 0
    public var invokedSelectParameters: (selection: ShareSelection, filterOption: ItemTypeFilterOption?)?
    public var invokedSelectParametersList = [(selection: ShareSelection, filterOption: ItemTypeFilterOption?)]()

    public func select(_ selection: ShareSelection, filterOption: ItemTypeFilterOption?) {
        invokedSelectfunction = true
        invokedSelectCount += 1
        invokedSelectParameters = (selection, filterOption)
        closureSelect()
    }
    // MARK: - refresh
    public var closureRefresh: () -> () = {}
    public var invokedRefreshfunction = false
    public var invokedRefreshCount = 0
    public var invokedRefreshParameters: (userId: String, Void)?
    public var invokedRefreshParametersList = [(userId: String, Void)]()

    public func refresh(userId: String) async {
        invokedRefreshfunction = true
        invokedRefreshCount += 1
        invokedRefreshParameters = (userId, ())
        closureRefresh()
    }
    // MARK: - fullSync
    public var closureFullSync: () -> () = {}
    public var invokedFullSyncfunction = false
    public var invokedFullSyncCount = 0
    public var invokedFullSyncParameters: (userId: String, Void)?
    public var invokedFullSyncParametersList = [(userId: String, Void)]()

    public func fullSync(userId: String) async {
        invokedFullSyncfunction = true
        invokedFullSyncCount += 1
        invokedFullSyncParameters = (userId, ())
        closureFullSync()
    }
    // MARK: - localFullSync
    public var localFullSyncUserIdThrowableError4: Error?
    public var closureLocalFullSync: () -> () = {}
    public var invokedLocalFullSyncfunction = false
    public var invokedLocalFullSyncCount = 0
    public var invokedLocalFullSyncParameters: (userId: String, Void)?
    public var invokedLocalFullSyncParametersList = [(userId: String, Void)]()

    public func localFullSync(userId: String) async throws {
        invokedLocalFullSyncfunction = true
        invokedLocalFullSyncCount += 1
        invokedLocalFullSyncParameters = (userId, ())
        if let error = localFullSyncUserIdThrowableError4 {
            throw error
        }
        closureLocalFullSync()
    }
    // MARK: - getItems
    public var closureGetItems: () -> () = {}
    public var invokedGetItemsfunction = false
    public var invokedGetItemsCount = 0
    public var invokedGetItemsParameters: (shareId: String, containerId: String?)?
    public var invokedGetItemsParametersList = [(shareId: String, containerId: String?)]()
    public nonisolated(unsafe) var stubbedGetItemsResult: [ItemUiModel]!

    public func getItems(for shareId: String, containerId: String?) -> [ItemUiModel] {
        invokedGetItemsfunction = true
        invokedGetItemsCount += 1
        invokedGetItemsParameters = (shareId, containerId)
        closureGetItems()
        return stubbedGetItemsResult
    }
    // MARK: - getAllItems
    public var closureGetAllItems: () -> () = {}
    public var invokedGetAllItemsfunction = false
    public var invokedGetAllItemsCount = 0
    public var invokedGetAllItemsParameters: (shareId: String, Void)?
    public var invokedGetAllItemsParametersList = [(shareId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetAllItemsResult: [ItemUiModel]!

    public func getAllItems(for shareId: String) -> [ItemUiModel] {
        invokedGetAllItemsfunction = true
        invokedGetAllItemsCount += 1
        invokedGetAllItemsParameters = (shareId, ())
        closureGetAllItems()
        return stubbedGetAllItemsResult
    }
    // MARK: - deleteUserIdShareId
    public var deleteUserIdShareIdThrowableError7: Error?
    public var closureDeleteUserIdShareIdAsync7: () -> () = {}
    public var invokedDeleteUserIdShareIdAsync7 = false
    public var invokedDeleteUserIdShareIdAsyncCount7 = 0
    public var invokedDeleteUserIdShareIdAsyncParameters7: (userId: String, shareId: String)?
    public var invokedDeleteUserIdShareIdAsyncParametersList7 = [(userId: String, shareId: String)]()

    public func delete(userId: String, shareId: String) async throws {
        invokedDeleteUserIdShareIdAsync7 = true
        invokedDeleteUserIdShareIdAsyncCount7 += 1
        invokedDeleteUserIdShareIdAsyncParameters7 = (userId, shareId)
        if let error = deleteUserIdShareIdThrowableError7 {
            throw error
        }
        closureDeleteUserIdShareIdAsync7()
    }
    // MARK: - deleteUserIdShareIdFolderId
    public var deleteUserIdShareIdFolderIdThrowableError8: Error?
    public var closureDeleteUserIdShareIdFolderIdAsync8: () -> () = {}
    public var invokedDeleteUserIdShareIdFolderIdAsync8 = false
    public var invokedDeleteUserIdShareIdFolderIdAsyncCount8 = 0
    public var invokedDeleteUserIdShareIdFolderIdAsyncParameters8: (userId: String, shareId: String, folderId: String)?
    public var invokedDeleteUserIdShareIdFolderIdAsyncParametersList8 = [(userId: String, shareId: String, folderId: String)]()

    public func delete(userId: String, shareId: String, folderId: String) async throws {
        invokedDeleteUserIdShareIdFolderIdAsync8 = true
        invokedDeleteUserIdShareIdFolderIdAsyncCount8 += 1
        invokedDeleteUserIdShareIdFolderIdAsyncParameters8 = (userId, shareId, folderId)
        if let error = deleteUserIdShareIdFolderIdThrowableError8 {
            throw error
        }
        closureDeleteUserIdShareIdFolderIdAsync8()
    }
    // MARK: - getOldestOwnedVault
    public var closureGetOldestOwnedVault: () -> () = {}
    public var invokedGetOldestOwnedVaultfunction = false
    public var invokedGetOldestOwnedVaultCount = 0
    public nonisolated(unsafe) var stubbedGetOldestOwnedVaultResult: Share?

    public func getOldestOwnedVault() async -> Share? {
        invokedGetOldestOwnedVaultfunction = true
        invokedGetOldestOwnedVaultCount += 1
        closureGetOldestOwnedVault()
        return stubbedGetOldestOwnedVaultResult
    }
    // MARK: - reset
    public var closureReset: () -> () = {}
    public var invokedResetfunction = false
    public var invokedResetCount = 0

    public func reset() async {
        invokedResetfunction = true
        invokedResetCount += 1
        closureReset()
    }
    // MARK: - moveFolder
    public var moveFolderThrowableError: Error?
    public var closureMoveFolder: () -> () = {}
    public var invokedMoveFolderfunction = false
    public var invokedMoveFolderCount = 0
    public var invokedMoveFolderParameters: (userId: String, shareId: String, folderId: String, newParentFolderId: String?)?
    public var invokedMoveFolderParametersList = [(userId: String, shareId: String, folderId: String, newParentFolderId: String?)]()

    public func moveFolder(userId: String, shareId: String, folderId: String, newParentFolderId: String?) async throws {
        invokedMoveFolderfunction = true
        invokedMoveFolderCount += 1
        invokedMoveFolderParameters = (userId, shareId, folderId, newParentFolderId)
        invokedMoveFolderParametersList.append((userId, shareId, folderId, newParentFolderId))
        if let error = moveFolderThrowableError {
            throw error
        }
        closureMoveFolder()
    }
}
