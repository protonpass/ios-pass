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
    /// Return `true` if user events is enabled
    func syncEventLoopDidBeginNewLoop(userId: String) async -> Bool

    /// Called when a loop is skipped
    /// - Parameters:
    ///    - reason: E.g no internet connection, previous loop not yet finished.
    func syncEventLoopDidSkipLoop(reason: SyncEventLoopSkipReason)

    /// Called after every successful sync loop.
    /// - Parameters:
    ///   - hasNewEvents: whether there are new events like items being updated or deleted.
    /// Client should rely on this boolean to act accordingly like refreshing the item list.
    func syncEventLoopDidFinishLoop(userId: String, hasNewEvents: Bool)

    /// Called when a sync loop is failed.
    /// - Parameters:
    ///   - error: Occured error
    func syncEventLoopDidFailLoop(userId: String, error: any Error)

    /// Called when an additional task is started to be executed
    /// - Parameters:
    ///  - label: the uniquely identifiable label of the failed task
    func syncEventLoopDidBeginExecutingAdditionalTask(userId: String, label: String)

    /// Called when an additional task is executed successfully
    /// - Parameters:
    func syncEventLoopDidFinishAdditionalTask(userId: String, label: String)

    /// Called when an additional task is failed
    /// - Parameters:
    ///  - label: the uniquely identifiable label of the failed task.
    ///  - error: the underlying error
    func syncEventLoopDidFailedAdditionalTask(userId: String, label: String, error: any Error)
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
    // periphery:ignore
    func addAdditionalTask(_ task: SyncEventLoop.AdditionalTask)
}

public extension SyncEventLoop {
    struct AdditionalTask: Sendable {
        /// Uniquely identiable label between tasks, each task should have a unique label
        /// This is to help the event loop adding/removing tasks
        let label: String
        /// The execution block of the task
        let task: @Sendable () async throws -> Void

        public init(label: String, task: @Sendable @escaping () async throws -> Void) {
            self.label = label
            self.task = task
        }

        public func callAsFunction() async throws {
            try await task()
        }
    }
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
    private var additionalTasks: [AdditionalTask] = []

    private var activeTasks = [String: Task<Void, any Error>]()

    // Injected params
    private let synchronizer: any EventSynchronizerProtocol
    private let userEventsSynchronizer: any UserEventsSynchronizerProtocol
    private let aliasSynchronizer: any AliasSynchronizerProtocol
    private let logger: Logger

    public weak var delegate: (any SyncEventLoopDelegate)?
    public weak var pullToRefreshDelegate: (any SyncEventLoopPullToRefreshDelegate)?

    private let queue = DispatchQueue(label: "me.proton.pass.synceventloop")

    public init(currentDateProvider: any CurrentDateProviderProtocol,
                synchronizer: any EventSynchronizerProtocol,
                userEventsSynchronizer: any UserEventsSynchronizerProtocol,
                aliasSynchronizer: any AliasSynchronizerProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol,
                reachability: any ReachabilityServicing) {
        backOffManager = BackOffManager(currentDateProvider: currentDateProvider)
        self.synchronizer = synchronizer
        self.userEventsSynchronizer = userEventsSynchronizer
        self.aliasSynchronizer = aliasSynchronizer
        logger = .init(manager: logManager)
        self.reachability = reachability
        self.userManager = userManager
    }

    public func reset() {
        stop()
        additionalTasks.removeAll()
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
            secondCount = 0
            delegate?.syncEventLoopDidStopLooping()
        }
    }

    func addAdditionalTask(_ task: AdditionalTask) {
        guard !additionalTasks.contains(where: { $0.label == task.label }) else {
            assertionFailure("Existing task with label \(task.label)")
            return
        }
        additionalTasks.append(task)
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
                if activeTasks[userData.user.ID] != nil {
                    delegate?.syncEventLoopDidSkipLoop(reason: .previousLoopNotFinished(userId: userData.user.ID))
                } else {
                    activeTasks[userData.user.ID] = Task { [weak self] in
                        guard let self else { return }

                        defer {
                            self.activeTasks[userData.user.ID] = nil
                            self.pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                        }

                        guard await backOffManager.canProceed() else {
                            pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                            delegate?.syncEventLoopDidSkipLoop(reason: .backOff)
                            return
                        }
                        await executeEventSync(currentUserId: userData.user.ID)
                    }
                }
            }
        }
    }

    func executeEventSync(currentUserId: String) async {
        do {
            let userEventsEnabled = await delegate?.syncEventLoopDidBeginNewLoop(userId: currentUserId)
            if Task.isCancelled { return }

            let hasNewEvents: Bool
            if userEventsEnabled == true {
                let result = try await userEventsSynchronizer.sync(userId: currentUserId)
                let syncedAliases = try await aliasSynchronizer.sync(userId: currentUserId)
                hasNewEvents = result.dataUpdated || syncedAliases
            } else {
                hasNewEvents = try await synchronizer.sync(userId: currentUserId)
            }

            // We only execute the additionalTasks for the main active account
            if let userId = userManager.activeUserId, userId == currentUserId {
                for task in additionalTasks {
                    do {
                        delegate?.syncEventLoopDidBeginExecutingAdditionalTask(userId: userId, label: task.label)
                        if Task.isCancelled { return }
                        try await task()
                        delegate?.syncEventLoopDidFinishAdditionalTask(userId: userId, label: task.label)
                    } catch {
                        delegate?.syncEventLoopDidFailedAdditionalTask(userId: userId,
                                                                       label: task.label,
                                                                       error: error)
                    }
                }
            }

            delegate?.syncEventLoopDidFinishLoop(userId: currentUserId, hasNewEvents: hasNewEvents)
            await backOffManager.recordSuccess()
        } catch {
            logger.error(error)
            delegate?.syncEventLoopDidFailLoop(userId: currentUserId, error: error)
            if let responseError = error as? ResponseError,
               let httpCode = responseError.httpCode,
               (500...599).contains(httpCode) {
                logger.debug("Server is down, backing off")
                await backOffManager.recordFailure()
            }
        }
    }
}
