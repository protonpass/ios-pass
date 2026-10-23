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
    /// Returns the operation before any work starts, for UI to observe
    @MainActor
    @discardableResult
    func callAsFunction(userId: String,
                        presentation: FullSyncPresentation,
                        shouldStopEventLoop: Bool) -> FullSyncOperation
}

public extension FullContentSyncUseCase {
    /// The event loop skips an account's iterations while it full syncs, but one could already be running
    /// when the full sync starts. `shouldStopEventLoop` cancels it to avoid a data race.
    ///
    /// User events can also require a full sync from inside an iteration. That caller must not stop
    /// the loop, which would cancel the very iteration waiting for the sync.
    /// - Returns: whether the sync completed. Failures are not thrown,
    /// so callers that announce the outcome must check this.
    @discardableResult
    func callAsFunction(userId: String, shouldStopEventLoop: Bool) async -> Bool {
        await callAsFunction(userId: userId, presentation: .sheet, shouldStopEventLoop: shouldStopEventLoop)
            .result()
            .isCompleted
    }
}

public struct FullContentSync: FullContentSyncUseCase {
    private let syncEventLoop: any SyncEventLoopProtocol
    private let fullSyncManager: any FullSyncManagerProtocol

    public init(syncEventLoop: any SyncEventLoopProtocol,
                fullSyncManager: any FullSyncManagerProtocol) {
        self.syncEventLoop = syncEventLoop
        self.fullSyncManager = fullSyncManager
    }

    @MainActor
    public func callAsFunction(userId: String,
                               presentation: FullSyncPresentation,
                               shouldStopEventLoop: Bool) -> FullSyncOperation {
        let operation = fullSyncManager.start(userId: userId, presentation: presentation)
        if shouldStopEventLoop {
            // Stopping cancels the running iteration, restarting right away is safe because
            // the account's iterations are skipped until its sync is done
            syncEventLoop.stop()
            syncEventLoop.start()
        }
        return operation
    }
}
