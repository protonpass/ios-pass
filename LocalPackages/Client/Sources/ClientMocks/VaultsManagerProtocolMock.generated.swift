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
import Combine
import Entities

public final class VaultsManagerProtocolMock: @unchecked Sendable, VaultsManagerProtocol {

    public init() {}

    // MARK: - currentVaults
    public var invokedCurrentVaultsSetter = false
    public var invokedCurrentVaultsSetterCount = 0
    public var invokedCurrentVaults: CurrentValueSubject<[Vault], Never>?
    public var invokedCurrentVaultsList = [CurrentValueSubject<[Vault], Never>?]()
    public var invokedCurrentVaultsGetter = false
    public var invokedCurrentVaultsGetterCount = 0
    public var stubbedCurrentVaults: CurrentValueSubject<[Vault], Never>!
    public var currentVaults: CurrentValueSubject<[Vault], Never> {
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

    public func refresh() {
        invokedRefreshfunction = true
        invokedRefreshCount += 1
        closureRefresh()
    }
    // MARK: - fullSync
    public var fullSyncThrowableError2: Error?
    public var closureFullSync: () -> () = {}
    public var invokedFullSyncfunction = false
    public var invokedFullSyncCount = 0

    public func fullSync() async throws {
        invokedFullSyncfunction = true
        invokedFullSyncCount += 1
        if let error = fullSyncThrowableError2 {
            throw error
        }
        closureFullSync()
    }
    // MARK: - getItems
    public var closureGetItems: () -> () = {}
    public var invokedGetItemsfunction = false
    public var invokedGetItemsCount = 0
    public var invokedGetItemsParameters: (vault: Vault, Void)?
    public var invokedGetItemsParametersList = [(vault: Vault, Void)]()
    public var stubbedGetItemsResult: [ItemUiModel]!

    public func getItems(for vault: Vault) -> [ItemUiModel] {
        invokedGetItemsfunction = true
        invokedGetItemsCount += 1
        invokedGetItemsParameters = (vault, ())
        invokedGetItemsParametersList.append((vault, ()))
        closureGetItems()
        return stubbedGetItemsResult
    }
    // MARK: - getItemCount
    public var closureGetItemCount: () -> () = {}
    public var invokedGetItemCountfunction = false
    public var invokedGetItemCountCount = 0
    public var invokedGetItemCountParameters: (selection: Vault, Void)?
    public var invokedGetItemCountParametersList = [(selection: Vault, Void)]()
    public var stubbedGetItemCountResult: Int!

    public func getItemCount(for selection: Vault) -> Int {
        invokedGetItemCountfunction = true
        invokedGetItemCountCount += 1
        invokedGetItemCountParameters = (selection, ())
        invokedGetItemCountParametersList.append((selection, ()))
        closureGetItemCount()
        return stubbedGetItemCountResult
    }
    // MARK: - getAllVaults
    public var closureGetAllVaults: () -> () = {}
    public var invokedGetAllVaultsfunction = false
    public var invokedGetAllVaultsCount = 0
    public var stubbedGetAllVaultsResult: [Vault]!

    public func getAllVaults() -> [Vault] {
        invokedGetAllVaultsfunction = true
        invokedGetAllVaultsCount += 1
        closureGetAllVaults()
        return stubbedGetAllVaultsResult
    }
    // MARK: - vaultHasTrashedItems
    public var closureVaultHasTrashedItems: () -> () = {}
    public var invokedVaultHasTrashedItemsfunction = false
    public var invokedVaultHasTrashedItemsCount = 0
    public var invokedVaultHasTrashedItemsParameters: (vault: Vault, Void)?
    public var invokedVaultHasTrashedItemsParametersList = [(vault: Vault, Void)]()
    public var stubbedVaultHasTrashedItemsResult: Bool!

    public func vaultHasTrashedItems(_ vault: Vault) -> Bool {
        invokedVaultHasTrashedItemsfunction = true
        invokedVaultHasTrashedItemsCount += 1
        invokedVaultHasTrashedItemsParameters = (vault, ())
        invokedVaultHasTrashedItemsParametersList.append((vault, ()))
        closureVaultHasTrashedItems()
        return stubbedVaultHasTrashedItemsResult
    }
    // MARK: - deleteVault
    public var deleteVaultThrowableError7: Error?
    public var closureDeleteVaultAsync7: () -> () = {}
    public var invokedDeleteVaultAsync7 = false
    public var invokedDeleteVaultAsyncCount7 = 0
    public var invokedDeleteVaultAsyncParameters7: (vault: Vault, Void)?
    public var invokedDeleteVaultAsyncParametersList7 = [(vault: Vault, Void)]()

    public func delete(vault: Vault) async throws {
        invokedDeleteVaultAsync7 = true
        invokedDeleteVaultAsyncCount7 += 1
        invokedDeleteVaultAsyncParameters7 = (vault, ())
        invokedDeleteVaultAsyncParametersList7.append((vault, ()))
        if let error = deleteVaultThrowableError7 {
            throw error
        }
        closureDeleteVaultAsync7()
    }
    // MARK: - deleteShareId
    public var deleteShareIdThrowableError8: Error?
    public var closureDeleteShareIdAsync8: () -> () = {}
    public var invokedDeleteShareIdAsync8 = false
    public var invokedDeleteShareIdAsyncCount8 = 0
    public var invokedDeleteShareIdAsyncParameters8: (shareId: String, Void)?
    public var invokedDeleteShareIdAsyncParametersList8 = [(shareId: String, Void)]()

    public func delete(shareId: String) async throws {
        invokedDeleteShareIdAsync8 = true
        invokedDeleteShareIdAsyncCount8 += 1
        invokedDeleteShareIdAsyncParameters8 = (shareId, ())
        invokedDeleteShareIdAsyncParametersList8.append((shareId, ()))
        if let error = deleteShareIdThrowableError8 {
            throw error
        }
        closureDeleteShareIdAsync8()
    }
    // MARK: - restoreAllTrashedItems
    public var restoreAllTrashedItemsThrowableError9: Error?
    public var closureRestoreAllTrashedItems: () -> () = {}
    public var invokedRestoreAllTrashedItemsfunction = false
    public var invokedRestoreAllTrashedItemsCount = 0

    public func restoreAllTrashedItems() async throws {
        invokedRestoreAllTrashedItemsfunction = true
        invokedRestoreAllTrashedItemsCount += 1
        if let error = restoreAllTrashedItemsThrowableError9 {
            throw error
        }
        closureRestoreAllTrashedItems()
    }
    // MARK: - permanentlyDeleteAllTrashedItems
    public var permanentlyDeleteAllTrashedItemsThrowableError10: Error?
    public var closurePermanentlyDeleteAllTrashedItems: () -> () = {}
    public var invokedPermanentlyDeleteAllTrashedItemsfunction = false
    public var invokedPermanentlyDeleteAllTrashedItemsCount = 0

    public func permanentlyDeleteAllTrashedItems() async throws {
        invokedPermanentlyDeleteAllTrashedItemsfunction = true
        invokedPermanentlyDeleteAllTrashedItemsCount += 1
        if let error = permanentlyDeleteAllTrashedItemsThrowableError10 {
            throw error
        }
        closurePermanentlyDeleteAllTrashedItems()
    }
    // MARK: - getOldestOwnedVault
    public var closureGetOldestOwnedVault: () -> () = {}
    public var invokedGetOldestOwnedVaultfunction = false
    public var invokedGetOldestOwnedVaultCount = 0
    public var stubbedGetOldestOwnedVaultResult: Vault?

    public func getOldestOwnedVault() -> Vault? {
        invokedGetOldestOwnedVaultfunction = true
        invokedGetOldestOwnedVaultCount += 1
        closureGetOldestOwnedVault()
        return stubbedGetOldestOwnedVaultResult
    }
    // MARK: - getFilteredItems
    public var closureGetFilteredItems: () -> () = {}
    public var invokedGetFilteredItemsfunction = false
    public var invokedGetFilteredItemsCount = 0
    public var stubbedGetFilteredItemsResult: [ItemUiModel]!

    public func getFilteredItems() -> [ItemUiModel] {
        invokedGetFilteredItemsfunction = true
        invokedGetFilteredItemsCount += 1
        closureGetFilteredItems()
        return stubbedGetFilteredItemsResult
    }
}
