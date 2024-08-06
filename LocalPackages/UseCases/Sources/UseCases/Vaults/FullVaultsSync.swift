//
//
// FullVaultsSync.swift
// Proton Pass - Created on 08/07/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import Client

public protocol FullVaultsSyncUseCase: Sendable {
    func execute(userId: String) async
}

public extension FullVaultsSyncUseCase {
    func callAsFunction(userId: String) async {
        await execute(userId: userId)
    }
}

public final class FullVaultsSync: FullVaultsSyncUseCase {
    private let syncEventLoop: any SyncEventLoopProtocol
    private let vaultsManager: any VaultsManagerProtocol

    public init(syncEventLoop: any SyncEventLoopProtocol,
                vaultsManager: any VaultsManagerProtocol) {
        self.syncEventLoop = syncEventLoop
        self.vaultsManager = vaultsManager
    }

    public func execute(userId: String) async {
        syncEventLoop.stop()
        await vaultsManager.fullSync(userId: userId)
        syncEventLoop.start()
    }
}
