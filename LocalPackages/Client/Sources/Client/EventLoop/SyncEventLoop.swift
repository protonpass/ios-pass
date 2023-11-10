//
// SyncEventLoop.swift
// Proton Pass - Created on 26/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Core
import Entities
import Foundation
import ProtonCoreNetworking
import Reachability

public protocol SyncEventLoopPullToRefreshDelegate: AnyObject {
    /// Do not care if the loop is finished with error or skipped.
    func pullToRefreshShouldStopRefreshing()
}

/// Emit operations of `SyncEventLoop` in detail. Should be implemeted by an application-wide object.
public protocol SyncEventLoopDelegate: AnyObject {
    /// Called when start looping
    func syncEventLoopDidStartLooping()

    /// Called when stop looping
    func syncEventLoopDidStopLooping()

    /// Called at the beginning of every sync loop.
    func syncEventLoopDidBeginNewLoop()

    /// Called when a loop is skipped
    /// - Parameters:
    ///    - reason: E.g no internet connection, previous loop not yet finished.
    func syncEventLoopDidSkipLoop(reason: SyncEventLoopSkipReason)

    /// Called after every successful sync loop.
    /// - Parameters:
    ///   - hasNewEvents: whether there are new events like items being updated or deleted.
    /// Client should rely on this boolean to act accordingly like refreshing the item list.
    func syncEventLoopDidFinishLoop(hasNewEvents: Bool)

    /// Called when a sync loop is failed.
    /// - Parameters:
    ///   - error: Occured error
    func syncEventLoopDidFailLoop(error: Error)

    /// Called when an additional task is started to be executed
    /// - Parameters:
    ///  - label: the uniquely identifiable label of the failed task
    func syncEventLoopDidBeginExecutingAdditionalTask(label: String)

    /// Called when an additional task is executed successfully
    /// - Parameters:
    func syncEventLoopDidFinishAdditionalTask(label: String)

    /// Called when an additional task is failed
    /// - Parameters:
    ///  - label: the uniquely identifiable label of the failed task.
    ///  - error: the underlying error
    func syncEventLoopDidFailedAdditionalTask(label: String, error: Error)
}

public protocol SyncEventLoopActionProtocol {
    func start()
    func stop()
    func forceSync()
    func addAdditionalTask(_ task: SyncEventLoop.AdditionalTask)
    func removeAdditionalTask(label: String)
}

public enum SyncEventLoopSkipReason {
    case noInternetConnection
    case previousLoopNotFinished
    case backOff
}

private let kThresholdRange = 5...15

// sourcery: AutoMockable
public protocol SyncEventLoopProtocol {
    func start()
    func forceSync()
    func stop()
}

public extension SyncEventLoop {
    struct AdditionalTask {
        /// Uniquely identiable label between tasks, each task should have a unique label
        /// This is to help the event loop adding/removing tasks
        let label: String
        /// The execution block of the task
        let task: () async throws -> Void

        public init(label: String, task: @escaping () async throws -> Void) {
            self.label = label
            self.task = task
        }

        public func callAsFunction() async throws {
            try await task()
        }
    }
}

/// A background event loop that keeps data up to date by synching after a random number of seconds
public final class SyncEventLoop: SyncEventLoopProtocol, DeinitPrintable {
    deinit { print(deinitMessage) }

    // Self-intialized params
    private let backOffManager: BackOffManagerProtocol
    private var reachability: Reachability?
    private var isReachable = true
    private var timer: Timer?
    private var secondCount = 0
    private var threshold = kThresholdRange.randomElement() ?? 5
    private var additionalTasks: [AdditionalTask] = []
    private var ongoingTask: Task<Void, Error>?

    // Injected params
    private let userDataProvider: UserDataProvider
    private let shareRepository: ShareRepositoryProtocol
    private let shareEventIDRepository: ShareEventIDRepositoryProtocol
    private let remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let shareKeyRepository: ShareKeyRepositoryProtocol
    private let logger: Logger

    public weak var delegate: SyncEventLoopDelegate?
    public weak var pullToRefreshDelegate: SyncEventLoopPullToRefreshDelegate?

    public init(currentDateProvider: CurrentDateProviderProtocol,
                userDataProvider: UserDataProvider,
                shareRepository: ShareRepositoryProtocol,
                shareEventIDRepository: ShareEventIDRepositoryProtocol,
                remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol,
                itemRepository: ItemRepositoryProtocol,
                shareKeyRepository: ShareKeyRepositoryProtocol,
                logManager: LogManagerProtocol) {
        backOffManager = BackOffManager(currentDateProvider: currentDateProvider)
        self.userDataProvider = userDataProvider
        self.shareRepository = shareRepository
        self.shareEventIDRepository = shareEventIDRepository
        self.remoteSyncEventsDatasource = remoteSyncEventsDatasource
        self.itemRepository = itemRepository
        self.shareKeyRepository = shareKeyRepository
        logger = .init(manager: logManager)
    }

    func makeReachabilityIfNecessary() throws {
        guard reachability == nil else { return }
        reachability = try .init()
        reachability?.whenReachable = { [weak self] _ in
            guard let self else { return }
            isReachable = true
        }
        reachability?.whenUnreachable = { [weak self] _ in
            guard let self else { return }
            isReachable = false
        }
        try reachability?.startNotifier()
    }

    public func reset() {
        stop()
        additionalTasks.removeAll()
    }
}

// MARK: - Public APIs

extension SyncEventLoop: SyncEventLoopActionProtocol {
    /// Start looping
    public func start() {
        delegate?.syncEventLoopDidStartLooping()
        stop()
        timer = .scheduledTimer(withTimeInterval: 1,
                                repeats: true) { [weak self] _ in
            guard let self else { return }
            secondCount += 1
            if secondCount >= threshold {
                secondCount = 0
                threshold = kThresholdRange.randomElement() ?? 5
                timerTask()
            }
        }
        timer?.fire()
    }

    /// Force a sync loop e.g when the app goes foreground, pull to refresh is triggered
    public func forceSync() {
        timerTask()
    }

    /// Stop looping
    public func stop() {
        timer?.invalidate()
        ongoingTask?.cancel()
        delegate?.syncEventLoopDidStopLooping()
    }

    public func addAdditionalTask(_ task: AdditionalTask) {
        guard !additionalTasks.contains(where: { $0.label == task.label }) else {
            assertionFailure("Existing task with label \(task.label)")
            return
        }
        additionalTasks.append(task)
    }

    public func removeAdditionalTask(label: String) {
        additionalTasks.removeAll(where: { $0.label == label })
    }
}

/*
 Steps of a sync:
 1. Fetch all shares from remote.
 2. Compare recently fetched shares with local ones.
    For each new share do the full sync procedure.
    For each existing share, do the step 3 of the full sync procedure.

 Full sync procedure:
 1. Get the last eventID from remote
 2. Get the share data (keys, items...) and store in the local db
 3. Get events from api using last eventID
    a. Upsert `UpdatedItems`
    b. Delete `DeletedItemIDs`
    c. Labels (Post MVP)
    d. If `NewRotationID` is not null. Refresh the keys of the share.
    e. Upsert `LatestEventID` of the share.
    f. If `EventsPending` is `true`. Repeat this step with the given `LatestEventID`.
 */

// MARK: - Private APIs

private extension SyncEventLoop {
    /// The repeated task of the timer
    func timerTask() {
        do {
            try makeReachabilityIfNecessary()
        } catch {
            logger.error(error)
            pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
            delegate?.syncEventLoopDidFailLoop(error: error)
        }

        guard isReachable else {
            pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
            delegate?.syncEventLoopDidSkipLoop(reason: .noInternetConnection)
            return
        }

        guard backOffManager.canProceed() else {
            pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
            delegate?.syncEventLoopDidSkipLoop(reason: .backOff)
            return
        }

        if ongoingTask != nil {
            delegate?.syncEventLoopDidSkipLoop(reason: .previousLoopNotFinished)
        } else {
            ongoingTask = Task { @MainActor [weak self] in
                guard let self else { return }
                defer {
                    self.ongoingTask = nil
                    self.pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                }

                do {
                    self.delegate?.syncEventLoopDidBeginNewLoop()
                    if Task.isCancelled {
                        return
                    }

                    let hasNewEvents = try await self.sync()

                    // Execute additional tasks and record failures in a different delegate callback
                    // So up to this point, the event loop is considered successful
                    for task in additionalTasks {
                        do {
                            self.delegate?.syncEventLoopDidBeginExecutingAdditionalTask(label: task.label)
                            try await task()
                            self.delegate?.syncEventLoopDidFinishAdditionalTask(label: task.label)
                        } catch {
                            self.delegate?.syncEventLoopDidFailedAdditionalTask(label: task.label,
                                                                                error: error)
                        }
                    }

                    self.delegate?.syncEventLoopDidFinishLoop(hasNewEvents: hasNewEvents)
                    self.backOffManager.recordSuccess()
                } catch {
                    self.logger.error(error)
                    self.delegate?.syncEventLoopDidFailLoop(error: error)
                    if let responseError = error as? ResponseError,
                       let httpCode = responseError.httpCode,
                       (500...599).contains(httpCode) {
                        self.logger.debug("Server is down, backing off")
                        self.backOffManager.recordFailure()
                    }
                }
            }
        }
    }

    /// Return `true` if new events found
    func sync() async throws -> Bool {
        // Need to sync 3 operations in 2 steps:
        // 1. Create & update sync
        // 2. Delete sync
        if Task.isCancelled {
            return false
        }

        let localShares = try await shareRepository.getShares()

        if Task.isCancelled {
            return false
        }

        let remoteShares = try await shareRepository.getRemoteShares()

        if Task.isCancelled {
            return false
        }

        var hasNewShareEvents = false
        // This is used to respond to sharing modifications that are not tied to events in the BE
        // making changes not visible to the user.
        if !remoteShares.isLooselyEqual(to: localShares.map(\.share)) {
            hasNewShareEvents = true

            // Update local shares
            let remainingLocalShares = localShares
                .filter { remoteShares.map(\.shareID).contains($0.share.shareID) }
            for share in remainingLocalShares {
                // A work around for a Core Data bug that fails the updates of booleans & numbers
                // We delete local shares instead of simply upserting and re-insert remote shares later on
                try await shareRepository.deleteShareLocally(shareId: share.share.shareID)
            }
            try await shareRepository.upsertShares(remoteShares)

            // Delete local shares if applicable
            let deletedLocalShares = localShares
                .filter { !remoteShares.map(\.shareID).contains($0.share.shareID) }
            if !deletedLocalShares.isEmpty {
                try await delete(shares: deletedLocalShares.map(\.share))
            }
        }

        let hasNewEvents = try await withThrowingTaskGroup(of: Bool.self,
                                                           returning: Bool.self) { taskGroup in
            taskGroup.addTask { [weak self] in
                guard let self else { return false }
                return try await syncCreateAndUpdateEvents(localShares: localShares,
                                                           remoteShares: remoteShares)
            }

            taskGroup.addTask { [weak self] in
                guard let self else { return false }
                return try await syncDeleteEvents(localShares: localShares,
                                                  remoteShares: remoteShares)
            }

            return try await taskGroup.contains { $0 }
        }

        return hasNewEvents || hasNewShareEvents
    }

    func delete(shares: [Share]) async throws {
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for share in shares {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    let shareId = share.shareID

                    if Task.isCancelled {
                        return
                    }
                    try await shareRepository.deleteShareLocally(shareId: shareId)
                    if Task.isCancelled {
                        return
                    }
                    try await itemRepository.deleteAllItemsLocally(shareId: shareId)
                }
            }
        }
    }

    /// Return `true` if new events found
    func syncCreateAndUpdateEvents(localShares: [SymmetricallyEncryptedShare],
                                   remoteShares: [Share]) async throws -> Bool {
        // Compare remote shares against local shares
        try await withThrowingTaskGroup(of: Bool.self, returning: Bool.self) { taskGroup in
            for remoteShare in remoteShares {
                // Task group returning `true` if new events found, `false` other wise
                taskGroup.addTask { [weak self] in
                    guard let self else { return false }
                    var hasNewEvents = false
                    if localShares.contains(where: { $0.share.shareID == remoteShare.shareID }) {
                        // Existing share
                        logger.trace("Existing share \(remoteShare.shareID)")
                        try await sync(share: remoteShare, hasNewEvents: &hasNewEvents)
                    } else {
                        // New share
                        logger.debug("New share \(remoteShare.shareID)")
                        hasNewEvents = true
                        let shareId = remoteShare.shareID
                        if Task.isCancelled {
                            return false
                        }

                        do {
                            _ = try await shareKeyRepository.refreshKeys(shareId: shareId)
                            try await shareRepository.upsertShares([remoteShare])
                            try await itemRepository.refreshItems(shareId: shareId)
                        } catch {
                            if let passError = error as? PassError,
                               case let .crypto(reason) = passError,
                               case .inactiveUserKey = reason {
                                // Ignore the case where user key is inactive
                                logger.warning(reason.debugDescription)
                            } else {
                                throw error
                            }
                        }
                    }
                    return hasNewEvents
                }
            }

            return try await taskGroup.contains { $0 }
        }
    }

    /// Return `true` if new events found
    func syncDeleteEvents(localShares: [SymmetricallyEncryptedShare],
                          remoteShares: [Share]) async throws -> Bool {
        // Compare local shares against remote shares
        try await withThrowingTaskGroup(of: Bool.self, returning: Bool.self) { taskGroup in
            for localShare in localShares {
                // Task group returning `true` if new events found, `false` other wise
                taskGroup.addTask { [weak self] in
                    guard let self else { return false }
                    let shareId = localShare.share.shareID
                    if !remoteShares.contains(where: { $0.shareID == shareId }) {
                        // We can blindly remove the local share and its items from the database
                        // but better to double check by asking the server
                        // and compare with a known error code "DISABLED_SHARE: 300004"
                        do {
                            // Expect an error here so passing a dummy boolean
                            logger.trace("Deleted share \(shareId)")
                            var dummyBoolean = false
                            try await sync(share: localShare.share, hasNewEvents: &dummyBoolean)
                        } catch {
                            if let responseError = error as? ResponseError,
                               responseError.responseCode == 300_004 {
                                // Confirmed that the vault is really deleted
                                // safe to delete it locally
                                if Task.isCancelled {
                                    return false
                                }
                                try await shareRepository.deleteShareLocally(shareId: shareId)
                                if Task.isCancelled {
                                    return false
                                }
                                try await itemRepository.deleteAllItemsLocally(shareId: shareId)
                                return true
                            }
                            throw error
                        }
                    }
                    return false
                }
            }

            return try await taskGroup.contains { $0 }
        }
    }

    /// Sync a single share. Can be a recursion if share has many events
    func sync(share: Share, hasNewEvents: inout Bool) async throws {
        let userId = try userDataProvider.getUserId()
        let shareId = share.shareID
        logger.trace("Syncing share \(shareId)")
        let lastEventId = try await shareEventIDRepository.getLastEventId(forceRefresh: false,
                                                                          userId: userId,
                                                                          shareId: shareId)
        let events = try await remoteSyncEventsDatasource.getEvents(shareId: shareId,
                                                                    lastEventId: lastEventId)
        try await shareEventIDRepository.upsertLastEventId(userId: userId,
                                                           shareId: shareId,
                                                           lastEventId: events.latestEventID)

        if events.fullRefresh {
            logger.info("Force full sync for share \(shareId)")
            hasNewEvents = true
            try await itemRepository.refreshItems(shareId: shareId)
            return
        }

        if let updatedShare = events.updatedShare {
            hasNewEvents = true
            logger.trace("Found updated share \(shareId)")
            try await shareRepository.upsertShares([updatedShare])
        }

        if !events.updatedItems.isEmpty {
            hasNewEvents = true
            logger.trace("Found \(events.updatedItems.count) updated items for share \(shareId)")
            try await itemRepository.upsertItems(events.updatedItems, shareId: shareId)
        }

        if !events.deletedItemIDs.isEmpty {
            hasNewEvents = true
            logger.trace("Found \(events.deletedItemIDs.count) deleted items for share \(shareId)")
            try await itemRepository.deleteItemsLocally(itemIds: events.deletedItemIDs,
                                                        shareId: shareId)
        }

        if events.newKeyRotation != nil {
            hasNewEvents = true
            logger.trace("Had new rotation ID for share \(shareId)")
            _ = try await shareKeyRepository.refreshKeys(shareId: shareId)
        }

        if events.eventsPending {
            logger.trace("Still have more events for share \(shareId)")
            try await sync(share: share, hasNewEvents: &hasNewEvents)
        }
    }
}
