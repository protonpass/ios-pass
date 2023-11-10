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
// swiftlint:disable all

@testable import Client
import Combine
import Entities

final class VaultsManagerProtocolMock: @unchecked Sendable, VaultsManagerProtocol {
    // MARK: - currentVaults
    var invokedCurrentVaultsSetter = false
    var invokedCurrentVaultsSetterCount = 0
    var invokedCurrentVaults: CurrentValueSubject<[Vault], Never>?
    var invokedCurrentVaultsList = [CurrentValueSubject<[Vault], Never>?]()
    var invokedCurrentVaultsGetter = false
    var invokedCurrentVaultsGetterCount = 0
    var stubbedCurrentVaults: CurrentValueSubject<[Vault], Never>!
    var currentVaults: CurrentValueSubject<[Vault], Never> {
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
    var invokedVaultSelectionSetter = false
    var invokedVaultSelectionSetterCount = 0
    var invokedVaultSelection: VaultSelection?
    var invokedVaultSelectionList = [VaultSelection?]()
    var invokedVaultSelectionGetter = false
    var invokedVaultSelectionGetterCount = 0
    var stubbedVaultSelection: VaultSelection!
    var vaultSelection: VaultSelection {
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
    var invokedHasOnlyOneOwnedVaultSetter = false
    var invokedHasOnlyOneOwnedVaultSetterCount = 0
    var invokedHasOnlyOneOwnedVault: Bool?
    var invokedHasOnlyOneOwnedVaultList = [Bool?]()
    var invokedHasOnlyOneOwnedVaultGetter = false
    var invokedHasOnlyOneOwnedVaultGetterCount = 0
    var stubbedHasOnlyOneOwnedVault: Bool!
    var hasOnlyOneOwnedVault: Bool {
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
    var closureRefresh: () -> () = {}
    var invokedRefresh = false
    var invokedRefreshCount = 0

    func refresh() {
        invokedRefresh = true
        invokedRefreshCount += 1
        closureRefresh()
    }
    // MARK: - fullSync
    var fullSyncThrowableError: Error?
    var closureFullSync: () -> () = {}
    var invokedFullSync = false
    var invokedFullSyncCount = 0

    func fullSync() async throws {
        invokedFullSync = true
        invokedFullSyncCount += 1
        if let error = fullSyncThrowableError {
            throw error
        }
        closureFullSync()
    }
    // MARK: - getItems
    var closureGetItems: () -> () = {}
    var invokedGetItems = false
    var invokedGetItemsCount = 0
    var invokedGetItemsParameters: (vault: Vault, Void)?
    var invokedGetItemsParametersList = [(vault: Vault, Void)]()
    var stubbedGetItemsResult: [ItemUiModel]!

    func getItems(for vault: Vault) -> [ItemUiModel] {
        invokedGetItems = true
        invokedGetItemsCount += 1
        invokedGetItemsParameters = (vault, ())
        invokedGetItemsParametersList.append((vault, ()))
        closureGetItems()
        return stubbedGetItemsResult
    }
    // MARK: - getItemCount
    var closureGetItemCount: () -> () = {}
    var invokedGetItemCount = false
    var invokedGetItemCountCount = 0
    var invokedGetItemCountParameters: (selection: Vault, Void)?
    var invokedGetItemCountParametersList = [(selection: Vault, Void)]()
    var stubbedGetItemCountResult: Int!

    func getItemCount(for selection: Vault) -> Int {
        invokedGetItemCount = true
        invokedGetItemCountCount += 1
        invokedGetItemCountParameters = (selection, ())
        invokedGetItemCountParametersList.append((selection, ()))
        closureGetItemCount()
        return stubbedGetItemCountResult
    }
    // MARK: - getAllVaults
    var closureGetAllVaults: () -> () = {}
    var invokedGetAllVaults = false
    var invokedGetAllVaultsCount = 0
    var stubbedGetAllVaultsResult: [Vault]!

    func getAllVaults() -> [Vault] {
        invokedGetAllVaults = true
        invokedGetAllVaultsCount += 1
        closureGetAllVaults()
        return stubbedGetAllVaultsResult
    }
    // MARK: - vaultHasTrashedItems
    var closureVaultHasTrashedItems: () -> () = {}
    var invokedVaultHasTrashedItems = false
    var invokedVaultHasTrashedItemsCount = 0
    var invokedVaultHasTrashedItemsParameters: (vault: Vault, Void)?
    var invokedVaultHasTrashedItemsParametersList = [(vault: Vault, Void)]()
    var stubbedVaultHasTrashedItemsResult: Bool!

    func vaultHasTrashedItems(_ vault: Vault) -> Bool {
        invokedVaultHasTrashedItems = true
        invokedVaultHasTrashedItemsCount += 1
        invokedVaultHasTrashedItemsParameters = (vault, ())
        invokedVaultHasTrashedItemsParametersList.append((vault, ()))
        closureVaultHasTrashedItems()
        return stubbedVaultHasTrashedItemsResult
    }
    // MARK: - delete
    var deleteVaultThrowableError: Error?
    var closureDelete: () -> () = {}
    var invokedDelete = false
    var invokedDeleteCount = 0
    var invokedDeleteParameters: (vault: Vault, Void)?
    var invokedDeleteParametersList = [(vault: Vault, Void)]()

    func delete(vault: Vault) async throws {
        invokedDelete = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (vault, ())
        invokedDeleteParametersList.append((vault, ()))
        if let error = deleteVaultThrowableError {
            throw error
        }
        closureDelete()
    }
    // MARK: - restoreAllTrashedItems
    var restoreAllTrashedItemsThrowableError: Error?
    var closureRestoreAllTrashedItems: () -> () = {}
    var invokedRestoreAllTrashedItems = false
    var invokedRestoreAllTrashedItemsCount = 0

    func restoreAllTrashedItems() async throws {
        invokedRestoreAllTrashedItems = true
        invokedRestoreAllTrashedItemsCount += 1
        if let error = restoreAllTrashedItemsThrowableError {
            throw error
        }
        closureRestoreAllTrashedItems()
    }
    // MARK: - permanentlyDeleteAllTrashedItems
    var permanentlyDeleteAllTrashedItemsThrowableError: Error?
    var closurePermanentlyDeleteAllTrashedItems: () -> () = {}
    var invokedPermanentlyDeleteAllTrashedItems = false
    var invokedPermanentlyDeleteAllTrashedItemsCount = 0

    func permanentlyDeleteAllTrashedItems() async throws {
        invokedPermanentlyDeleteAllTrashedItems = true
        invokedPermanentlyDeleteAllTrashedItemsCount += 1
        if let error = permanentlyDeleteAllTrashedItemsThrowableError {
            throw error
        }
        closurePermanentlyDeleteAllTrashedItems()
    }
    // MARK: - getOldestOwnedVault
    var closureGetOldestOwnedVault: () -> () = {}
    var invokedGetOldestOwnedVault = false
    var invokedGetOldestOwnedVaultCount = 0
    var stubbedGetOldestOwnedVaultResult: Vault?

    func getOldestOwnedVault() -> Vault? {
        invokedGetOldestOwnedVault = true
        invokedGetOldestOwnedVaultCount += 1
        closureGetOldestOwnedVault()
        return stubbedGetOldestOwnedVaultResult
    }
    // MARK: - getFilteredItems
    var closureGetFilteredItems: () -> () = {}
    var invokedGetFilteredItems = false
    var invokedGetFilteredItemsCount = 0
    var stubbedGetFilteredItemsResult: [ItemUiModel]!

    func getFilteredItems() -> [ItemUiModel] {
        invokedGetFilteredItems = true
        invokedGetFilteredItemsCount += 1
        closureGetFilteredItems()
        return stubbedGetFilteredItemsResult
    }
}
