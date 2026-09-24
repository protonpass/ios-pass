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
    /// The event loop skips its iterations while a full sync runs, but one could already be running
    /// when the full sync starts. `shouldStopEventLoop` cancels it to avoid a data race.
    ///
    /// However, user events system could also trigger a force full refresh,
    /// this is the only case where we shouldn't stop the event loop because user events happen inside
    /// event loop, so if we stop the loop, the full sync will be cancelled.
    /// - Returns: whether the sync completed. Failures are not thrown,
    /// so callers that announce the outcome must check this.
    @discardableResult
    func execute(userId: String, shouldStopEventLoop: Bool) async -> Bool

    /// Same as `execute` but returns the operation before any work starts, for UI to observe
    @MainActor
    @discardableResult
    func start(userId: String,
               presentation: FullSyncPresentation,
               shouldStopEventLoop: Bool) -> FullSyncOperation
}

public extension FullContentSyncUseCase {
    @discardableResult
    func callAsFunction(userId: String, shouldStopEventLoop: Bool) async -> Bool {
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

    public func execute(userId: String, shouldStopEventLoop: Bool) async -> Bool {
        await start(userId: userId, presentation: .sheet, shouldStopEventLoop: shouldStopEventLoop)
            .result()
            .succeeded
    }

    @MainActor
    public func start(userId: String,
                      presentation: FullSyncPresentation,
                      shouldStopEventLoop: Bool) -> FullSyncOperation {
        let operation = appContentManager.startFullSync(userId: userId, presentation: presentation)
        if shouldStopEventLoop {
            // Stopping cancels the running iteration, restarting right away is safe because
            // iterations are skipped until no full sync is left
            syncEventLoop.stop()
            syncEventLoop.start()
        }
        return operation
    }
}
