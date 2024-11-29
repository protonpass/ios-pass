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
    nonisolated var vaultSyncEventStream: CurrentValueSubject<VaultSyncProgressEvent, Never> { get }
    var currentVaults: CurrentValueSubject<[Share], Never> { get }
    var vaultSelection: VaultSelection { get }
    var hasOnlyOneOwnedVault: Bool { get }

    func refresh(userId: String)
    func fullSync(userId: String) async
    func localFullSync(userId: String) async throws
    func getItems(for vault: Share) -> [ItemUiModel]
    func getAllVaults() -> [Share]
    func delete(userId: String, shareId: String) async throws
    func getOldestOwnedVault() -> Share?
    func reset() async
}
