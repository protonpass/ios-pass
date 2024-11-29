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
import Entities

public final class VaultsManagerProtocolMock: @unchecked Sendable, VaultsManagerProtocol {

    public init() {}

    // MARK: - vaultSyncEventStream
    public var invokedVaultSyncEventStreamSetter = false
    public var invokedVaultSyncEventStreamSetterCount = 0
    public var invokedVaultSyncEventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?
    public var invokedVaultSyncEventStreamList = [CurrentValueSubject<VaultSyncProgressEvent, Never>?]()
    public var invokedVaultSyncEventStreamGetter = false
    public var invokedVaultSyncEventStreamGetterCount = 0
    public var stubbedVaultSyncEventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>!
    public var vaultSyncEventStream: CurrentValueSubject<VaultSyncProgressEvent, Never> {
        set {
            invokedVaultSyncEventStreamSetter = true
            invokedVaultSyncEventStreamSetterCount += 1
            invokedVaultSyncEventStream = newValue
            invokedVaultSyncEventStreamList.append(newValue)
        } get {
            invokedVaultSyncEventStreamGetter = true
            invokedVaultSyncEventStreamGetterCount += 1
            return stubbedVaultSyncEventStream
        }
    }
    // MARK: - currentVaults
    public var invokedCurrentVaultsSetter = false
    public var invokedCurrentVaultsSetterCount = 0
    public var invokedCurrentVaults: CurrentValueSubject<[Share], Never>?
    public var invokedCurrentVaultsList = [CurrentValueSubject<[Share], Never>?]()
    public var invokedCurrentVaultsGetter = false
    public var invokedCurrentVaultsGetterCount = 0
    public var stubbedCurrentVaults: CurrentValueSubject<[Share], Never>!
    public var currentVaults: CurrentValueSubject<[Share], Never> {
        set {
            invokedCurrentVaultsSetter = true
            invokedCurrentVaultsSetterCount += 1
            invokedCurrentVaults = newValue
            invokedCurrentVaultsList.append(newValue)
        } get {
            invokedCurrentVaultsGetter = true
            invokedCurrentVaultsGetterCount += 1
            return stubbedCurrentVaults
        }
    }
    // MARK: - vaultSelection
    public var invokedVaultSelectionSetter = false
    public var invokedVaultSelectionSetterCount = 0
    public var invokedVaultSelection: VaultSelection?
    public var invokedVaultSelectionList = [VaultSelection?]()
    public var invokedVaultSelectionGetter = false
    public var invokedVaultSelectionGetterCount = 0
    public var stubbedVaultSelection: VaultSelection!
    public var vaultSelection: VaultSelection {
        set {
            invokedVaultSelectionSetter = true
            invokedVaultSelectionSetterCount += 1
            invokedVaultSelection = newValue
            invokedVaultSelectionList.append(newValue)
        } get {
            invokedVaultSelectionGetter = true
            invokedVaultSelectionGetterCount += 1
            return stubbedVaultSelection
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
    // MARK: - refresh
    public var closureRefresh: () -> () = {}
    public var invokedRefreshfunction = false
    public var invokedRefreshCount = 0
    public var invokedRefreshParameters: (userId: String, Void)?
    public var invokedRefreshParametersList = [(userId: String, Void)]()

    public func refresh(userId: String) {
        invokedRefreshfunction = true
        invokedRefreshCount += 1
        invokedRefreshParameters = (userId, ())
        invokedRefreshParametersList.append((userId, ()))
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
        invokedFullSyncParametersList.append((userId, ()))
        closureFullSync()
    }
    // MARK: - localFullSync
    public var localFullSyncUserIdThrowableError3: Error?
    public var closureLocalFullSync: () -> () = {}
    public var invokedLocalFullSyncfunction = false
    public var invokedLocalFullSyncCount = 0
    public var invokedLocalFullSyncParameters: (userId: String, Void)?
    public var invokedLocalFullSyncParametersList = [(userId: String, Void)]()

    public func localFullSync(userId: String) async throws {
        invokedLocalFullSyncfunction = true
        invokedLocalFullSyncCount += 1
        invokedLocalFullSyncParameters = (userId, ())
        invokedLocalFullSyncParametersList.append((userId, ()))
        if let error = localFullSyncUserIdThrowableError3 {
            throw error
        }
        closureLocalFullSync()
    }
    // MARK: - getItems
    public var closureGetItems: () -> () = {}
    public var invokedGetItemsfunction = false
    public var invokedGetItemsCount = 0
    public var invokedGetItemsParameters: (vault: Share, Void)?
    public var invokedGetItemsParametersList = [(vault: Share, Void)]()
    public var stubbedGetItemsResult: [ItemUiModel]!

    public func getItems(for vault: Share) -> [ItemUiModel] {
        invokedGetItemsfunction = true
        invokedGetItemsCount += 1
        invokedGetItemsParameters = (vault, ())
        invokedGetItemsParametersList.append((vault, ()))
        closureGetItems()
        return stubbedGetItemsResult
    }
    // MARK: - getAllVaults
    public var closureGetAllVaults: () -> () = {}
    public var invokedGetAllVaultsfunction = false
    public var invokedGetAllVaultsCount = 0
    public var stubbedGetAllVaultsResult: [Share]!

    public func getAllVaults() -> [Share] {
        invokedGetAllVaultsfunction = true
        invokedGetAllVaultsCount += 1
        closureGetAllVaults()
        return stubbedGetAllVaultsResult
    }
    // MARK: - delete
    public var deleteUserIdShareIdThrowableError6: Error?
    public var closureDelete: () -> () = {}
    public var invokedDeletefunction = false
    public var invokedDeleteCount = 0
    public var invokedDeleteParameters: (userId: String, shareId: String)?
    public var invokedDeleteParametersList = [(userId: String, shareId: String)]()

    public func delete(userId: String, shareId: String) async throws {
        invokedDeletefunction = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (userId, shareId)
        invokedDeleteParametersList.append((userId, shareId))
        if let error = deleteUserIdShareIdThrowableError6 {
            throw error
        }
        closureDelete()
    }
    // MARK: - getOldestOwnedVault
    public var closureGetOldestOwnedVault: () -> () = {}
    public var invokedGetOldestOwnedVaultfunction = false
    public var invokedGetOldestOwnedVaultCount = 0
    public var stubbedGetOldestOwnedVaultResult: Share?

    public func getOldestOwnedVault() -> Share? {
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
