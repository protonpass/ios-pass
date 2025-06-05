//
//
// FullContentSync.swift
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

public protocol FullContentSyncUseCase: Sendable {
    /// We should always stop the event loop before triggering a full sync to avoid data race
    /// in case the full sync happens in the middle of a sync loop
    ///
    /// However, user events system could also trigger a force full refresh,
    /// this is the only case where we shouldn't stop the event loop because user events happen inside
    /// event loop, so if we stop the loop, the full sync will be cancelled.
    func execute(userId: String, shouldStopEventLoop: Bool) async
}

public extension FullContentSyncUseCase {
    func callAsFunction(userId: String, shouldStopEventLoop: Bool) async {
        await execute(userId: userId, shouldStopEventLoop: shouldStopEventLoop)
    }
}

public final class FullContentSync: FullContentSyncUseCase {
    private let syncEventLoop: any SyncEventLoopProtocol
    private let appContentManager: any AppContentManagerProtocol

    public init(syncEventLoop: any SyncEventLoopProtocol,
                appContentManager: any AppContentManagerProtocol) {
        self.syncEventLoop = syncEventLoop
        self.appContentManager = appContentManager
    }

    public func execute(userId: String, shouldStopEventLoop: Bool) async {
        if shouldStopEventLoop {
            syncEventLoop.stop()
        }
        await appContentManager.fullSync(userId: userId)
        if shouldStopEventLoop {
            syncEventLoop.start()
        }
    }
}
