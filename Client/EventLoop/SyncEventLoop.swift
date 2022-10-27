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

private let kEventLoopIntervalInSeconds: TimeInterval = 30

public protocol SyncEventLoopDelegate: AnyObject {
    /// Called when start looping
    func syncEventLoopDidStartLooping()

    /// Called when stop looping
    func syncEventLoopDidStopLooping()

    /// Called at the beginning of every sync loop.
    func syncEventLoopDidBeginNewLoop()

    /// Called when a loop is skipped because previous loop is still being processed
    func syncEventLoopDidSkipLoop()

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

/// A background event loop that keeps data up to date by synching after a given time interval
public final class SyncEventLoop {
    private var timer: Timer?
    private var ongoingTask: Task<Void, Error>?

    public weak var delegate: SyncEventLoopDelegate?

    public init() {}

    /// Start looping
    public func start() {
        delegate?.syncEventLoopDidStartLooping()
        timer = .scheduledTimer(withTimeInterval: kEventLoopIntervalInSeconds,
                                repeats: true) { [unowned self] _ in
            if self.ongoingTask != nil {
                self.delegate?.syncEventLoopDidSkipLoop()
            } else {
                self.ongoingTask = Task {
                    defer { self.ongoingTask = nil }
                    do {
                        self.delegate?.syncEventLoopDidBeginNewLoop()
                        try await longRunningTask()
                        self.delegate?.syncEventLoopDidFinishLoop(hasNewEvents: true)
                    } catch {
                        self.delegate?.syncEventLoopDidFailLoop(error: error)
                    }
                }
            }
        }
        timer?.fire()
    }

    /// Stop looping
    public func stop() {
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
private extension SyncEventLoop {
    func longRunningTask() async throws {
        print("Started new task")
        try await Task.sleep(nanoseconds: 13_000_000_000)
        print("Stopped task")
    }
}
