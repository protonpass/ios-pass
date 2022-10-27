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
import Foundation
import Reachability

private let kEventLoopIntervalInSeconds: TimeInterval = 30

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

/// A background event loop that keeps data up to date by synching after a given time interval
public final class SyncEventLoop {
    // Self-intialized params
    private var reachability: Reachability?
    private var isReachable = true
    private var timer: Timer?
    private var ongoingTask: Task<Void, Error>?

    // Injected params
    private let userId: String
    private let shareRepository: ShareRepositoryProtocol
    private let shareEventIDRepository: ShareEventIDRepositoryProtocol
    private let remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol

    public weak var delegate: SyncEventLoopDelegate?

    public init(userId: String,
                shareRepository: ShareRepositoryProtocol,
                shareEventIDRepository: ShareEventIDRepositoryProtocol,
                remoteSyncEventsDatasource: RemoteSyncEventsDatasourceProtocol) {
        self.userId = userId
        self.shareRepository = shareRepository
        self.shareEventIDRepository = shareEventIDRepository
        self.remoteSyncEventsDatasource = remoteSyncEventsDatasource
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
        timer = .scheduledTimer(withTimeInterval: kEventLoopIntervalInSeconds,
                                repeats: true) { [unowned self] _ in
            self.timerTask()
        }
        timer?.fire()
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
            delegate?.syncEventLoopDidFailLoop(error: error)
        }

        guard isReachable else {
            delegate?.syncEventLoopDidSkipLoop(reason: .noInternetConnection)
            return
        }

        if ongoingTask != nil {
            delegate?.syncEventLoopDidSkipLoop(reason: .previousLoopNotFinished)
        } else {
            ongoingTask = Task {
                defer { ongoingTask = nil }
                do {
                    delegate?.syncEventLoopDidBeginNewLoop()
                    try await sync()
                    delegate?.syncEventLoopDidFinishLoop(hasNewEvents: true)
                } catch {
                    delegate?.syncEventLoopDidFailLoop(error: error)
                }
            }
        }
    }

    func sync() async throws {}
}
