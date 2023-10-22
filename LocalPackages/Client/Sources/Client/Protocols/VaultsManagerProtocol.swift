//
// VaultsManagerProtocol.swift
// Proton Pass - Created on 03/10/2023.
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

import Combine
import Entities

// sourcery: AutoMockable
public protocol VaultsManagerProtocol: Sendable {
    var currentVaults: CurrentValueSubject<[Vault], Never> { get }
    var vaultSelection: VaultSelection { get }
    var hasOnlyOneOwnedVault: Bool { get }

    func refresh()
    func fullSync() async throws
    func getItems(for vault: Vault) -> [ItemUiModel]
    func getItemCount(for selection: Vault) -> Int
    func getAllVaults() -> [Vault]
    func vaultHasTrashedItems(_ vault: Vault) -> Bool
    func delete(vault: Vault) async throws
    func restoreAllTrashedItems() async throws
    func permanentlyDeleteAllTrashedItems() async throws
    func getPrimaryVault() -> Vault?
    func getOldestOwnedVault() -> Vault?
    func getFilteredItems() -> [ItemUiModel]
}