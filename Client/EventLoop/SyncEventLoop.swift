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
import Foundation
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
}

public enum SyncEventLoopSkipReason {
    case noInternetConnection
    case previousLoopNotFinished
}

private let kThresholdRange = 5...15

/// A background event loop that keeps data up to date by synching after a random number of seconds
public final class SyncEventLoop: DeinitPrintable {
    deinit { print(deinitMessage) }

    // Self-intialized params
    private var reachability: Reachability?
    private var isReachable = true
    private var timer: Timer?
    private var secondCount = 0
    private var threshold = kThresholdRange.randomElement() ?? 5
    private var ongoingTask: Task<Void, Error>?

    // Injected params
    private let userId: String
    private let shareRepository: ShareRepositoryProtocol
    private let shareEventIDRepository: ShareEventIDRepositoryProtocol
    private let remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let shareKeyRepository: ShareKeyRepositoryProtocol
    private let logger: Logger

    public weak var delegate: SyncEventLoopDelegate?
    public weak var pullToRefreshDelegate: SyncEventLoopPullToRefreshDelegate?

    public init(userId: String,
                shareRepository: ShareRepositoryProtocol,
                shareEventIDRepository: ShareEventIDRepositoryProtocol,
                remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol,
                itemRepository: ItemRepositoryProtocol,
                shareKeyRepository: ShareKeyRepositoryProtocol,
                logManager: LogManager) {
        self.userId = userId
        self.shareRepository = shareRepository
        self.shareEventIDRepository = shareEventIDRepository
        self.remoteSyncEventsDatasource = remoteSyncEventsDatasource
        self.itemRepository = itemRepository
        self.shareKeyRepository = shareKeyRepository
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }

    func makeReachabilityIfNecessary() throws {
        guard reachability == nil else { return }
        reachability = try .init()
        reachability?.whenReachable = { [weak self] _ in self?.isReachable = true }
        reachability?.whenUnreachable = { [weak self] _ in self?.isReachable = false }
        try reachability?.startNotifier()
    }
}

// MARK: - Public APIs
public extension SyncEventLoop {
    /// Start looping
    func start() {
        delegate?.syncEventLoopDidStartLooping()
        timer = .scheduledTimer(withTimeInterval: 1,
                                repeats: true) { [weak self] _ in
            guard let self else { return }
            self.secondCount += 1
            if self.secondCount >= self.threshold {
                self.secondCount = 0
                self.threshold = kThresholdRange.randomElement() ?? 5
                self.timerTask()
            }
        }
        timer?.fire()
    }

    /// Force a sync loop e.g when the app goes foreground, pull to refresh is triggered
    func forceSync() {
        timerTask()
    }

    /// Stop looping
    func stop() {
        timer?.invalidate()
        ongoingTask?.cancel()
        delegate?.syncEventLoopDidStopLooping()
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

        if ongoingTask != nil {
            delegate?.syncEventLoopDidSkipLoop(reason: .previousLoopNotFinished)
        } else {
            ongoingTask = Task { @MainActor in
                defer {
                    ongoingTask = nil
                    pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                }

                do {
                    delegate?.syncEventLoopDidBeginNewLoop()
                    let hasNewEvents = try await sync()
                    delegate?.syncEventLoopDidFinishLoop(hasNewEvents: hasNewEvents)
                } catch {
                    logger.error(error)
                    delegate?.syncEventLoopDidFailLoop(error: error)
                }
            }
        }
    }

    /// Return `true` if new events found
    func sync() async throws -> Bool {
        let localShares = try await shareRepository.getShares()
        let remoteShares = try await shareRepository.getRemoteShares()

        return try await withThrowingTaskGroup(of: Bool.self, returning: Bool.self) { taskGroup in
            for remoteShare in remoteShares {
                taskGroup.addTask {
                    var hasNewEvents = false
                    if localShares.contains(where: { $0.shareID == remoteShare.shareID }) {
                        // Existing share
                        try await self.sync(share: remoteShare, hasNewEvents: &hasNewEvents)
                    } else {
                        // New share
                        let shareId = remoteShare.shareID
                        _ = try await self.shareKeyRepository.refreshKeys(shareId: shareId)
                        try await self.sync(share: remoteShare, hasNewEvents: &hasNewEvents)
                    }
                    return hasNewEvents
                }
            }

            return try await taskGroup.reduce(into: false) { partialResult, nextValue in
                partialResult = partialResult || nextValue
            }
        }
    }

    /// Sync a single share. Can be a recursion if share has many events
    func sync(share: Share, hasNewEvents: inout Bool) async throws {
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
            try await itemRepository.refreshShare(shareId: shareId)
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
