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
    // MARK: - isFullSyncing
    public var invokedIsFullSyncingSetter = false
    public var invokedIsFullSyncingSetterCount = 0
    public var invokedIsFullSyncing: Bool?
    public var invokedIsFullSyncingList = [Bool?]()
    public var invokedIsFullSyncingGetter = false
    public var invokedIsFullSyncingGetterCount = 0
    public var stubbedIsFullSyncing: Bool!

    public var isFullSyncing: Bool {
        set {
            invokedIsFullSyncingSetter = true
            invokedIsFullSyncingSetterCount += 1
            invokedIsFullSyncing = newValue
            invokedIsFullSyncingList.append(newValue)
        } get {
            invokedIsFullSyncingGetter = true
            invokedIsFullSyncingGetterCount += 1
            return stubbedIsFullSyncing
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
    // MARK: - getShareContent
    public var closureGetShareContent: () -> () = {}
    public var invokedGetShareContentfunction = false
    public var invokedGetShareContentCount = 0
    public var invokedGetShareContentParameters: (shareId: String, Void)?
    public var invokedGetShareContentParametersList = [(shareId: String, Void)]()
    public nonisolated(unsafe) var stubbedGetShareContentResult: ShareContent?

    public func getShareContent(for shareId: String) -> ShareContent? {
        invokedGetShareContentfunction = true
        invokedGetShareContentCount += 1
        invokedGetShareContentParameters = (shareId, ())
        closureGetShareContent()
        return stubbedGetShareContentResult
    }
    // MARK: - getItems
    public var closureGetItems: () -> () = {}
    public var invokedGetItemsfunction = false
    public var invokedGetItemsCount = 0
    public var invokedGetItemsParameters: (shareId: String, containerId: String?)?
    public var invokedGetItemsParametersList = [(shareId: String, containerId: String?)]()
    public nonisolated(unsafe) var stubbedGetItemsResult: [ItemUiModel]!

    public func getItems(shareId: String, containerId: String?) -> [ItemUiModel] {
        invokedGetItemsfunction = true
        invokedGetItemsCount += 1
        invokedGetItemsParameters = (shareId, containerId)
        closureGetItems()
        return stubbedGetItemsResult
    }
    // MARK: - delete
    public var deleteUserIdShareIdThrowableError7: Error?
    public var closureDelete: () -> () = {}
    public var invokedDeletefunction = false
    public var invokedDeleteCount = 0
    public var invokedDeleteParameters: (userId: String, shareId: String)?
    public var invokedDeleteParametersList = [(userId: String, shareId: String)]()

    public func delete(userId: String, shareId: String) async throws {
        invokedDeletefunction = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (userId, shareId)
        if let error = deleteUserIdShareIdThrowableError7 {
            throw error
        }
        closureDelete()
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
}
