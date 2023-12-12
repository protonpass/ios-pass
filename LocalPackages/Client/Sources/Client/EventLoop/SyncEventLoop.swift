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
    func syncEventLoopDidFailLoop(error: any Error)

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
    func syncEventLoopDidFailedAdditionalTask(label: String, error: any Error)
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

private let kThresholdRange = 55...60

// sourcery: AutoMockable
public protocol SyncEventLoopProtocol {
    func start()
    func forceSync()
    func stop()
    func reset()
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
public final class SyncEventLoop: SyncEventLoopProtocol, DeinitPrintable, Sendable {
    deinit { print(deinitMessage) }

    // Self-intialized params
    private let backOffManager: any BackOffManagerProtocol
    private let reachability: any ReachabilityServicing
    private var timer: Timer?
    private var secondCount = 0
    private var threshold = kThresholdRange.randomElement() ?? 5
    private var additionalTasks: [AdditionalTask] = []
    private var ongoingTask: Task<Void, any Error>?

    // Injected params
    private let synchronizer: any EventSynchronizerProtocol
    private let logger: Logger

    public weak var delegate: (any SyncEventLoopDelegate)?
    public weak var pullToRefreshDelegate: (any SyncEventLoopPullToRefreshDelegate)?

    public init(currentDateProvider: any CurrentDateProviderProtocol,
                synchronizer: any EventSynchronizerProtocol,
                logManager: any LogManagerProtocol,
                reachability: any ReachabilityServicing) {
        backOffManager = BackOffManager(currentDateProvider: currentDateProvider)
        self.synchronizer = synchronizer
        logger = .init(manager: logManager)
        self.reachability = reachability
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
        guard timer == nil else { return }
        delegate?.syncEventLoopDidStartLooping()
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
        ongoingTask?.cancel()
        ongoingTask = nil
        timer?.invalidate()
        timer = nil
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

// MARK: - Private APIs

private extension SyncEventLoop {
    /// The repeated task of the timer
    func timerTask() {
        guard reachability.isNetworkAvailable.value else {
            pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
            delegate?.syncEventLoopDidSkipLoop(reason: .noInternetConnection)
            return
        }

        if ongoingTask != nil {
            delegate?.syncEventLoopDidSkipLoop(reason: .previousLoopNotFinished)
        } else {
            ongoingTask = Task { @MainActor [weak self] in
                guard let self else { return }
                defer {
                    ongoingTask = nil
                    pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                }

                guard await backOffManager.canProceed() else {
                    pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
                    delegate?.syncEventLoopDidSkipLoop(reason: .backOff)
                    return
                }

                do {
                    delegate?.syncEventLoopDidBeginNewLoop()
                    if Task.isCancelled {
                        return
                    }

                    let hasNewEvents = try await synchronizer.sync()

                    // Execute additional tasks and record failures in a different delegate callback
                    // So up to this point, the event loop is considered successful
                    for task in additionalTasks {
                        do {
                            delegate?.syncEventLoopDidBeginExecutingAdditionalTask(label: task.label)
                            try await task()
                            delegate?.syncEventLoopDidFinishAdditionalTask(label: task.label)
                        } catch {
                            delegate?.syncEventLoopDidFailedAdditionalTask(label: task.label,
                                                                           error: error)
                        }
                    }

                    delegate?.syncEventLoopDidFinishLoop(hasNewEvents: hasNewEvents)
                    await backOffManager.recordSuccess()
                } catch {
                    logger.error(error)
                    delegate?.syncEventLoopDidFailLoop(error: error)
                    if let responseError = error as? ResponseError,
                       let httpCode = responseError.httpCode,
                       (500...599).contains(httpCode) {
                        logger.debug("Server is down, backing off")
                        await backOffManager.recordFailure()
                    }
                }
            }
        }
    }
}
