//
// FullSyncManager.swift
// Proton Pass - Created on 21/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Core
import Entities
import Foundation
import UseCases

@MainActor
public protocol FullSyncManagerDelegate: AnyObject, Sendable {
    func fullSyncDidFinish(userId: String) async throws
}

@MainActor
public final class FullSyncManager: FullSyncManagerProtocol {
    /// The latest full sync started or joined, kept after it finishes so observers can read its outcome
    @Published public private(set) var fullSyncOperation: FullSyncOperation?

    public weak var delegate: (any FullSyncManagerDelegate)?

    /// Accounts whose last full sync wiped their local data without completing
    public private(set) var incompleteFullSyncUserIds: Set<String> {
        get {
            let userIds = kSharedUserDefaults.stringArray(forKey: Constants.incompleteFullSyncUserIds) ?? []
            // swiftlint:disable:next todo
            // TODO: Added on Oct 2026, could be removed several months later
            let legacyUserId = kSharedUserDefaults.string(forKey: Constants.incompleteFullSyncUserId)
            return Set(userIds + [legacyUserId].compactMap(\.self))
        }
        set {
            kSharedUserDefaults.set(Array(newValue), forKey: Constants.incompleteFullSyncUserIds)
            kSharedUserDefaults.removeObject(forKey: Constants.incompleteFullSyncUserId)
        }
    }

    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let inviteRepository: any FullInviteRepositoryProtocol
    private let folderRepository: any FolderRepositoryProtocol
    private let slNoteSynchronizer: any SimpleLoginNoteSynchronizerProtocol
    private let refreshUserData: any RefreshUserDataUseCase
    private let deleteLocalDataBeforeFullSync: any DeleteLocalDataBeforeFullSyncUseCase
    private let getAndStoreLastEventId: any GetAndStoreLastEventIdUseCase
    private let logger: Logger
    private let fullSyncStallTimeout: Duration

    /// Running sync first, then the ones queued behind it
    private var fullSyncTasks: [(operation: FullSyncOperation, task: Task<Void, Never>)] = []

    public init(itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                inviteRepository: any FullInviteRepositoryProtocol,
                folderRepository: any FolderRepositoryProtocol,
                slNoteSynchronizer: any SimpleLoginNoteSynchronizerProtocol,
                refreshUserData: any RefreshUserDataUseCase,
                deleteLocalDataBeforeFullSync: any DeleteLocalDataBeforeFullSyncUseCase,
                getAndStoreLastEventId: any GetAndStoreLastEventIdUseCase,
                logger: Logger,
                fullSyncStallTimeout: Duration = .seconds(180)) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.inviteRepository = inviteRepository
        self.folderRepository = folderRepository
        self.slNoteSynchronizer = slNoteSynchronizer
        self.refreshUserData = refreshUserData
        self.deleteLocalDataBeforeFullSync = deleteLocalDataBeforeFullSync
        self.getAndStoreLastEventId = getAndStoreLastEventId
        self.logger = logger
        self.fullSyncStallTimeout = fullSyncStallTimeout
    }

    /// Includes a sync still queued behind another account's, which has not marked the account yet
    public func isFullSyncing(userId: String) -> Bool {
        fullSyncTasks.contains { $0.operation.userId == userId && $0.operation.outcome == nil }
    }

    /// Unlike `isFullSyncing(userId:)`, also counts the alias notes written after the sync finished
    /// and a stalled sync whose task has not returned yet
    public func hasFullSyncTask(userId: String) -> Bool {
        fullSyncTasks.contains { $0.operation.userId == userId }
    }

    /// Deletes everything and downloads again. Returns before any work starts so the UI can bind
    /// to the operation straight away.
    ///
    /// A request for a user whose sync is already in flight joins it instead of wiping twice, and
    /// publishes it again for observers that skipped it, e.g. while its account was inactive.
    /// Syncs of different users run one after the other, never in parallel.
    @discardableResult
    public func start(userId: String, presentation: FullSyncPresentation) -> FullSyncOperation {
        if let joined = fullSyncTasks.first(where: {
            $0.operation.userId == userId && $0.operation.outcome == nil && !$0.task.isCancelled
        }) {
            logger.info("Full sync already in progress, joining it for user \(userId)")
            fullSyncOperation = joined.operation
            return joined.operation
        }

        let operation = FullSyncOperation(userId: userId, presentation: presentation)
        let previous = fullSyncTasks.last
        if let previous, previous.operation.outcome != nil {
            // Its alias notes would hold this sync back with no stall watchdog
            previous.task.cancel()
        }
        let task = Task { [weak self] in
            await previous?.task.value
            guard let self else {
                operation.finish(.cancelled)
                return
            }
            let outcome: FullSyncOperation.Outcome = if Task.isCancelled {
                .cancelled
            } else {
                await performFullSync(operation)
            }
            operation.finish(outcome)
            // The published outcome, so a stalled sync that completes anyway stays a failure. Notes are only a
            // cache that opening an alias fills too, so they give way to a sync waiting behind this one.
            if operation.outcome?.isCompleted == true, fullSyncTasks.last?.operation === operation {
                // Still part of the task so the next sync can't wipe the items while their notes are written
                await syncAliasNotes(userId: operation.userId)
            }
            fullSyncTasks.removeAll { $0.operation === operation }
        }
        fullSyncTasks.append((operation, task))
        fullSyncOperation = operation
        return operation
    }

    /// Waits for the account's running sync to return so it writes nothing once the account is removed.
    /// Queued syncs are not awaited, they return as cancelled before doing any work.
    public func cancel(userId: String) async {
        let running = fullSyncTasks.first
        fullSyncTasks.filter { $0.operation.userId == userId }.forEach { $0.task.cancel() }
        if let running, running.operation.userId == userId {
            await running.task.value
        }
        incompleteFullSyncUserIds.remove(userId)
    }

    /// Waits for cancelled syncs to return so none of them writes data after the reset
    public func reset() async {
        let tasks = fullSyncTasks.map(\.task)
        tasks.forEach { $0.cancel() }
        fullSyncOperation = nil
        incompleteFullSyncUserIds = []
        for task in tasks {
            await task.value
        }
    }
}

private extension FullSyncManager {
    func performFullSync(_ operation: FullSyncOperation) async -> FullSyncOperation.Outcome {
        let userId = operation.userId
        let (progressEvents, events) = AsyncStream.makeStream(of: VaultSyncProgressEvent.self)
        // The repository actors yield progress while this function awaits them, so the events are applied
        // in a separate main actor task. It ends once `events.finish()` runs, and `apply` drops late events.
        Task {
            for await event in progressEvents {
                operation.apply(event)
            }
        }
        defer { events.finish() }
        let stallWatchdog = Task { [weak self] in
            guard let self else { return }
            await failWhenStalled(operation)
        }
        defer { stallWatchdog.cancel() }

        logger.info("Starting full sync \(operation.id) for user \(userId)")
        var hasUndecryptableShares = false
        do {
            // 0. Refresh user data to handle account changes like added address keys
            try startStep(operation)
            try await refreshUserData(userId: userId)

            // 1. Delete all local data
            try startStep(operation)
            incompleteFullSyncUserIds.insert(userId)
            try await deleteLocalDataBeforeFullSync(userId: userId)

            // 2. Get all remote shares and their items
            try startStep(operation)
            let remoteShares = try await shareRepository.getDecryptedRemoteShares(userId: userId)
            hasUndecryptableShares = remoteShares.hasUndecryptableShares
            events.yield(.downloadedShares(remoteShares.shares.representingVaults))

            try startStep(operation)
            try await withThrowingTaskGroup(of: Void.self) { taskGroup in
                async let upsertSharesTask: Void = shareRepository.upsertShares(userId: userId,
                                                                                shares: remoteShares.shares,
                                                                                eventStream: events)

                for share in remoteShares.shares {
                    taskGroup.addTask { [self] in
                        try Task.checkCancellation()
                        if share.shareType == .vault {
                            try await folderRepository.refreshFolders(userId: userId,
                                                                      shareId: share.shareID)
                        }

                        try Task.checkCancellation()
                        try await itemRepository.refreshItems(userId: userId,
                                                              shareId: share.shareID,
                                                              eventStream: events)
                    }
                }

                _ = try await (upsertSharesTask, taskGroup.waitForAll())
            }

            // 3. Create default vault if no vaults
            try startStep(operation)
            try await createDefaultVaultIfNeeded(userId: userId, shares: remoteShares.shares)

            // 4. Refresh invites
            try startStep(operation)
            await refreshInvites(userId: userId)

            // 5. Get the lastEventID as a starting point for user events sync loop
            try startStep(operation)
            try await getAndStoreLastEventId(userId: userId)

            // Last so the delegate only acts on a sync that succeeded
            try startStep(operation)
            assert(delegate != nil, "Full sync delegate not set")
            try await delegate?.fullSyncDidFinish(userId: userId)
        } catch {
            if error is CancellationError || Task.isCancelled {
                logger.info("Cancelled full sync \(operation.id) for user \(userId)")
                return .cancelled
            }
            logger.error(message: "Failed full sync \(operation.id) for user \(userId)", error: error)
            return .failed(error)
        }

        incompleteFullSyncUserIds.remove(userId)
        logger.info("Finished full sync \(operation.id) for user \(userId)")
        return .completed(hasUndecryptableShares: hasUndecryptableShares)
    }

    func startStep(_ operation: FullSyncOperation) throws {
        try Task.checkCancellation()
        operation.recordActivity()
    }

    /// Fails a sync with no activity for `fullSyncStallTimeout` so the user gets the retry screen
    /// instead of an endless spinner. The outcome is published before cancelling because a call
    /// that ignores cancellation keeps the task, and any sync queued behind it, alive until it returns.
    ///
    /// Counts ticks instead of reading a clock: clocks keep running while the app is suspended in
    /// the background, so a single sleep would fail the sync the moment the app comes back.
    func failWhenStalled(_ operation: FullSyncOperation) async {
        let ticksBeforeStall = 10
        var lastActivity = operation.activity
        var stalledTicks = 0
        while await (try? Task.sleep(for: fullSyncStallTimeout / ticksBeforeStall)) != nil {
            guard operation.activity == lastActivity else {
                lastActivity = operation.activity
                stalledTicks = 0
                continue
            }
            stalledTicks += 1
            guard stalledTicks == ticksBeforeStall else { continue }
            let error = URLError(.timedOut)
            logger.error(message: "Full sync \(operation.id) made no progress", error: error)
            operation.finish(.failed(error))
            fullSyncTasks.first { $0.operation === operation }?.task.cancel()
            return
        }
    }

    func createDefaultVaultIfNeeded(userId: String, shares: [Share]) async throws {
        guard shares.representingVaults.isEmpty else { return }
        do {
            logger.trace("Creating default vault for user")
            try await shareRepository.createVault(userId: userId, vault: .defaultVault)
            logger.info("Created default vault for user")
        } catch {
            guard let apiError = error.asPassApiError,
                  apiError == .notAllowed else {
                throw error
            }
            // Can't create default vault because of B2B policy
            // Do nothing and just move on
        }
    }

    func refreshInvites(userId: String) async {
        do {
            try await inviteRepository.refreshAllInvites(userId: userId)
        } catch {
            // We logs the errors silently to let the full content refresh continue offering a better
            // experience to the user.
            logger.error(error)
        }
    }

    /// Runs after the sync has finished so the progress UI closes once the items are loaded:
    /// the notes are only read when an alias is opened, and their request has taken 15 s before failing.
    func syncAliasNotes(userId: String) async {
        do {
            _ = try await slNoteSynchronizer.syncAllAliases(userId: userId)
        } catch is CancellationError {
            logger.info("Stopped syncing alias notes for user \(userId)")
        } catch {
            logger.error(error)
        }
    }
}
