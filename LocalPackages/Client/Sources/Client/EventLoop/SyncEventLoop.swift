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
import ProtonCoreNetworking

public protocol SyncEventLoopPullToRefreshDelegate: AnyObject, Sendable {
    /// Do not care if the loop is finished with error or skipped.
    func pullToRefreshShouldStopRefreshing()
}

/// Emit operations of `SyncEventLoop` in detail. Should be implemeted by an application-wide object.
public protocol SyncEventLoopDelegate: AnyObject, Sendable {
    /// Called when start looping
    func syncEventLoopDidStartLooping()

    /// Called when stop looping
    func syncEventLoopDidStopLooping()

    /// Called at the beginning of every sync loop.
    func syncEventLoopDidBeginNewLoop(userId: String)

    /// Called when a loop is skipped
    /// - Parameters:
    ///    - reason: E.g no internet connection, previous loop not yet finished.
    func syncEventLoopDidSkipLoop(reason: SyncEventLoopSkipReason)

    /// Triggered by user events system when the users are too outdated and a new full sync is needed
    func syncEventLoopRequiresFullSync(userId: String) async throws

    /// Called after every successful sync loop.
    /// - Parameters:
    ///   - hasNewEvents: whether there are new events like items being updated or deleted.
    /// Client should rely on this boolean to act accordingly like refreshing the item list.
    func syncEventLoopDidFinishLoop(userId: String, hasNewEvents: Bool)

    /// Called when a sync loop is failed.
    /// - Parameters:
    ///   - error: Occured error
    func syncEventLoopDidFailLoop(userId: String, error: any Error)
}

public enum SyncEventLoopSkipReason {
    case noInternetConnection
    case previousLoopNotFinished(userId: String)
    case backOff
}

private let kThresholdRange = 55...60

// sourcery: AutoMockable
public protocol SyncEventLoopProtocol: Sendable {
    func forceSync()
    func reset()
    func start()
    func stop()
}

public final class SyncEventLoop: SyncEventLoopProtocol, DeinitPrintable, @unchecked Sendable {
    deinit { print(deinitMessage) }

    // Self-initialized params
    private let backOffManager: any BackOffManagerProtocol
    private let reachability: any ReachabilityServicing
    private let userManager: any UserManagerProtocol
    private var timerTask: Task<Void, Never>?
    private var fetchEventsTask: Task<Void, Never>?

    private var secondCount = 0
    private var threshold = kThresholdRange.randomElement() ?? 5
    private var activeTasks = [String: Task<Void, any Error>]()

    // Injected params
    private let userEventsSynchronizer: any UserEventsSynchronizerProtocol
    private let coreEventsSynchronizer: any CoreEventsSynchronizerProtocol
    private let logger: Logger

    public weak var delegate: (any SyncEventLoopDelegate)?
    public weak var pullToRefreshDelegate: (any SyncEventLoopPullToRefreshDelegate)?

    private let queue = DispatchQueue(label: "me.proton.pass.synceventloop")

    public init(currentDateProvider: any CurrentDateProviderProtocol,
                userEventsSynchronizer: any UserEventsSynchronizerProtocol,
                coreEventsSynchronizer: any CoreEventsSynchronizerProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol,
                reachability: any ReachabilityServicing) {
        backOffManager = BackOffManager(currentDateProvider: currentDateProvider)
        self.userEventsSynchronizer = userEventsSynchronizer
        self.coreEventsSynchronizer = coreEventsSynchronizer
        logger = .init(manager: logManager)
        self.reachability = reachability
        self.userManager = userManager
    }

    public func reset() {
        stop()
    }
}

// MARK: - Public APIs

public extension SyncEventLoop {
    /// Start looping
    func start() {
        queue.sync { [weak self] in
            guard let self else { return }
            guard timerTask == nil else {
                return
            }

            delegate?.syncEventLoopDidStartLooping()
            timerTask = Task { [weak self] in
                guard let self else { return }
                await timerLoop()
            }
        }
    }

    /// Force a sync loop e.g when the app goes foreground, pull to refresh is triggered
    func forceSync() {
        fetchEvents()
    }

    /// Stop looping
    func stop() {
        queue.sync { [weak self] in
            guard let self else { return }

            for (key, task) in activeTasks {
                task.cancel()
                activeTasks[key] = nil
            }
            timerTask?.cancel()
            timerTask = nil
            fetchEventsTask?.cancel()
            fetchEventsTask = nil
            secondCount = 0
            delegate?.syncEventLoopDidStopLooping()
        }
    }
}

// MARK: - Private APIs

private extension SyncEventLoop {
    /// Timer loop using async/await
    func timerLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(seconds: 1)

            guard !Task.isCancelled else { return }

            secondCount += 1

            if secondCount >= threshold {
                secondCount = 0
                threshold = kThresholdRange.randomElement() ?? 5
                fetchEvents()
            }
        }
    }

    /// The repeated task of the timer
    func fetchEvents() {
        guard fetchEventsTask == nil else {
            return
        }
        fetchEventsTask = Task { @MainActor [weak self] in
            defer {
                // swiftlint:disable discouraged_optional_self
                self?.fetchEventsTask?.cancel()
                self?.fetchEventsTask = nil
                // swiftlint:enable discouraged_optional_self
            }

            guard let self else {
                return
            }

            guard reachability.isNetworkAvailable.value else {
                pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                delegate?.syncEventLoopDidSkipLoop(reason: .noInternetConnection)
                return
            }

            for userData in userManager.allUserAccounts.value {
                let userId = userData.user.ID
                if activeTasks[userId] != nil {
                    delegate?.syncEventLoopDidSkipLoop(reason: .previousLoopNotFinished(userId: userId))
                } else {
                    activeTasks[userId] = Task { [weak self] in
                        guard let self else { return }

                        defer {
                            activeTasks[userId] = nil
                            pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                        }

                        guard await backOffManager.canProceed() else {
                            pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                            delegate?.syncEventLoopDidSkipLoop(reason: .backOff)
                            return
                        }
                        await executeEventSync(userId: userId)
                    }
                }
            }
        }
    }

    func executeEventSync(userId: String) async {
        do {
            delegate?.syncEventLoopDidBeginNewLoop(userId: userId)
            if Task.isCancelled {
                return
            }

            try await coreEventsSynchronizer.sync(userId: userId)

            let hasNewEvents: Bool
            let result = try await userEventsSynchronizer.sync(userId: userId)

            if result.contains(.fullRefreshNeeded) {
                try await delegate?.syncEventLoopRequiresFullSync(userId: userId)
                return
            }

            hasNewEvents = result.contains(.dataUpdated)

            delegate?.syncEventLoopDidFinishLoop(userId: userId, hasNewEvents: hasNewEvents)
            await backOffManager.recordSuccess()
        } catch {
            logger.error(error)
            delegate?.syncEventLoopDidFailLoop(userId: userId, error: error)
            if let responseError = error as? ResponseError,
               let httpCode = responseError.httpCode,
               (500...599).contains(httpCode) {
                logger.debug("Server is down, backing off")
                await backOffManager.recordFailure()
            }
        }
    }
}
