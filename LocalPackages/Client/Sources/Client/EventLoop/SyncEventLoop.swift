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

public protocol SyncEventLoopActionProtocol: Sendable {
    func start()
    func stop()
    func forceSync()
    func addAdditionalTask(_ task: SyncEventLoop.AdditionalTask)
}

public enum SyncEventLoopSkipReason {
    case noInternetConnection
    case previousLoopNotFinished
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

/// A background event loop that keeps data up to date by synching after a random number of seconds
public final class SyncEventLoop: SyncEventLoopProtocol, SyncEventLoopActionProtocol, DeinitPrintable,
    @unchecked Sendable {
    deinit { print(deinitMessage) }

    // Self-intialized params
    private let backOffManager: any BackOffManagerProtocol
    private let reachability: any ReachabilityServicing
    private let userManager: any UserManagerProtocol
    private var timer: Timer?
    private var secondCount = 0
    private var threshold = kThresholdRange.randomElement() ?? 5
    private var additionalTasks: [AdditionalTask] = []
    private var ongoingTask: Task<Void, any Error>?

//    private var activeTasks = [String: Task<Void, any Error>]()

    // Injected params
    private let synchronizer: any EventSynchronizerProtocol
    private let logger: Logger

    public weak var delegate: (any SyncEventLoopDelegate)?
    public weak var pullToRefreshDelegate: (any SyncEventLoopPullToRefreshDelegate)?

    public init(currentDateProvider: any CurrentDateProviderProtocol,
                synchronizer: any EventSynchronizerProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol,
                reachability: any ReachabilityServicing) {
        backOffManager = BackOffManager(currentDateProvider: currentDateProvider)
        self.synchronizer = synchronizer
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
    func forceSync() {
        timerTask()
    }

    /// Stop looping
    func stop() {
        // TODO: stop all tasks
        ongoingTask?.cancel()
        ongoingTask = nil
        timer?.invalidate()
        timer = nil
        delegate?.syncEventLoopDidStopLooping()
    }

    func addAdditionalTask(_ task: AdditionalTask) {
        guard !additionalTasks.contains(where: { $0.label == task.label }) else {
            assertionFailure("Existing task with label \(task.label)")
            return
        }
        additionalTasks.append(task)
    }

//    func removeAdditionalTask(label: String) {
//        additionalTasks.removeAll(where: { $0.label == label })
//    }
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

//        for userAccount in userManager.allUserAccounts.value {
//            refreshUserData(userId: userAccount.user.ID)
//        }

        // TODO: loop on all account (dic of task with user id)
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

                    let userId = try await userManager.getActiveUserId()

                    let hasNewEvents = try await synchronizer.sync(userId: userId)

                    // Execute additional tasks and record failures in a different delegate callback
                    // So up to this point, the event loop is considered successful
                    for task in additionalTasks {
                        do {
                            delegate?.syncEventLoopDidBeginExecutingAdditionalTask(label: task.label)
                            if Task.isCancelled {
                                return
                            }
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

//    func refreshUserData(userId: String) {
//        if let existingTask = activeTasks[userId] {
//            if checkAndHandleCancellation(for: userId) { return }
//            delegate?.syncEventLoopDidSkipLoop(reason: .previousLoopNotFinished)
//        }
//
//        guard await backOffManager.canProceed() else {
//            pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
//            delegate?.syncEventLoopDidSkipLoop(reason: .backOff)
//            return
//        }
//
//        if checkAndHandleCancellation(for: userId) { return }
    ////        let task = Task { [weak self] in
    ////            // swiftlint:disable:next discouraged_optional_self
    ////            try await self?.fetchAndCacheIcon(for: domain)
    ////        }
    ////
//        let task = Task { @MainActor [weak self] in
//            guard let self else { return }
//            defer {
//                task = nil
//                pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
//            }
//
//            guard await backOffManager.canProceed() else {
//                pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
//                delegate?.syncEventLoopDidSkipLoop(reason: .backOff)
//                return
//            }
//
//            do {
//                delegate?.syncEventLoopDidBeginNewLoop()
//                if Task.isCancelled {
//                    return
//                }
//
//                let hasNewEvents = try await synchronizer.sync()
//
//                // Execute additional tasks and record failures in a different delegate callback
//                // So up to this point, the event loop is considered successful
//                for task in additionalTasks {
//                    do {
//                        delegate?.syncEventLoopDidBeginExecutingAdditionalTask(label: task.label)
//                        if Task.isCancelled {
//                            return
//                        }
//                        try await task()
//                        delegate?.syncEventLoopDidFinishAdditionalTask(label: task.label)
//                    } catch {
//                        delegate?.syncEventLoopDidFailedAdditionalTask(label: task.label,
//                                                                       error: error)
//                    }
//                }
//
//                delegate?.syncEventLoopDidFinishLoop(hasNewEvents: hasNewEvents)
//                await backOffManager.recordSuccess()
//            } catch {
//                logger.error(error)
//                delegate?.syncEventLoopDidFailLoop(error: error)
//                if let responseError = error as? ResponseError,
//                   let httpCode = responseError.httpCode,
//                   (500...599).contains(httpCode) {
//                    logger.debug("Server is down, backing off")
//                    await backOffManager.recordFailure()
//                }
//            }
//        }
//        addActiveTask(task, for: domain)
//        if checkAndHandleCancellation(for: domain) { return nil }
//        return try await task.value
//
//
//
//        // TODO: loop on all account (dic of task with user id)
//        if ongoingTask != nil {
//            delegate?.syncEventLoopDidSkipLoop(reason: .previousLoopNotFinished)
//        } else {
//            ongoingTask = Task { @MainActor [weak self] in
//                guard let self else { return }
//                defer {
//                    ongoingTask = nil
//                    pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
//                }
//
//                guard await backOffManager.canProceed() else {
//                    pullToRefreshDelegate?.pullToRefreshShouldStopRefreshing()
//                    delegate?.syncEventLoopDidSkipLoop(reason: .backOff)
//                    return
//                }
//
//                do {
//                    delegate?.syncEventLoopDidBeginNewLoop()
//                    if Task.isCancelled {
//                        return
//                    }
//
//                    let hasNewEvents = try await synchronizer.sync()
//
//                    // Execute additional tasks and record failures in a different delegate callback
//                    // So up to this point, the event loop is considered successful
//                    for task in additionalTasks {
//                        do {
//                            delegate?.syncEventLoopDidBeginExecutingAdditionalTask(label: task.label)
//                            if Task.isCancelled {
//                                return
//                            }
//                            try await task()
//                            delegate?.syncEventLoopDidFinishAdditionalTask(label: task.label)
//                        } catch {
//                            delegate?.syncEventLoopDidFailedAdditionalTask(label: task.label,
//                                                                           error: error)
//                        }
//                    }
//
//                    delegate?.syncEventLoopDidFinishLoop(hasNewEvents: hasNewEvents)
//                    await backOffManager.recordSuccess()
//                } catch {
//                    logger.error(error)
//                    delegate?.syncEventLoopDidFailLoop(error: error)
//                    if let responseError = error as? ResponseError,
//                       let httpCode = responseError.httpCode,
//                       (500...599).contains(httpCode) {
//                        logger.debug("Server is down, backing off")
//                        await backOffManager.recordFailure()
//                    }
//                }
//            }
//        }
//    }
//
//
//
//    func addActiveTask(_ task: Task<Void, any Error>, for userId: String) {
//        activeTasks[userId] = task
//    }
//
//    func cancelAndRemoveTask(for userId: String) {
//        activeTasks[userId]?.cancel()
//        activeTasks[userId] = nil
//    }
//
//    func checkAndHandleCancellation(for userId: String) -> Bool {
//        if Task.isCancelled {
//            cancelAndRemoveTask(for: userId)
//            return true
//        }
//        return false
//    }
}

//    func getIcon(for domain: String) async throws -> FavIcon? {
//        guard !domain.isEmpty else { return nil }
//
//        if let existingTask = activeTasks[domain] {
//            if checkAndHandleCancellation(for: domain) { return nil }
//            return try await existingTask.value
//        }
//
//        if checkAndHandleCancellation(for: domain) { return nil }
//        let task = Task { [weak self] in
//            // swiftlint:disable:next discouraged_optional_self
//            try await self?.fetchAndCacheIcon(for: domain)
//        }
//        addActiveTask(task, for: domain)
//        if checkAndHandleCancellation(for: domain) { return nil }
//        return try await task.value
//    }

//
//
// public actor FavIconRepository: FavIconRepositoryProtocol, DeinitPrintable {
//    deinit { print(deinitMessage) }
//
//    private let datasource: any RemoteFavIconDatasourceProtocol
//    /// URL to the folder that contains cached fav icons
//    private let containerUrl: URL
//    private let cacheExpirationDays: Int
//    private let symmetricKeyProvider: any SymmetricKeyProvider
//    private var activeTasks = [String: Task<FavIcon?, any Error>]()
//    private let userManager: any UserManagerProtocol
//
//    public init(datasource: any RemoteFavIconDatasourceProtocol,
//                containerUrl: URL,
//                symmetricKeyProvider: any SymmetricKeyProvider,
//                userManager: any UserManagerProtocol,
//                cacheExpirationDays: Int = 14) {
//        self.datasource = datasource
//        self.containerUrl = containerUrl
//        self.cacheExpirationDays = cacheExpirationDays
//        self.symmetricKeyProvider = symmetricKeyProvider
//        self.userManager = userManager
//    }
// }
//
// public extension FavIconRepository {
//    /// Fetches the favicon for the specified domain.
//    /// - If the icon is already being fetched, it waits for the existing task to complete.
//    /// - If the icon is cached and not obsolete, it returns the cached version.
//    /// - Otherwise, it fetches the icon from the remote source and caches it.
//    /// Parameters:
//    ///   - domain: The domain for which to fetch the favicon.
//    /// Returns: The fetched `FavIcon` object, or `nil` if the operation fails or is cancelled.
//    func getIcon(for domain: String) async throws -> FavIcon? {
//        guard !domain.isEmpty else { return nil }
//
//        if let existingTask = activeTasks[domain] {
//            if checkAndHandleCancellation(for: domain) { return nil }
//            return try await existingTask.value
//        }
//
//        if checkAndHandleCancellation(for: domain) { return nil }
//        let task = Task { [weak self] in
//            // swiftlint:disable:next discouraged_optional_self
//            try await self?.fetchAndCacheIcon(for: domain)
//        }
//        addActiveTask(task, for: domain)
//        if checkAndHandleCancellation(for: domain) { return nil }
//        return try await task.value
//    }
//
//    func getAllCachedIcons() async throws -> [FavIcon] {
//        let urls = try FileManager.default.contentsOfDirectory(at: containerUrl,
//                                                               includingPropertiesForKeys: nil)
//
//        let getDecryptedData: (URL) async throws -> Data? = { [weak self] url in
//            guard let self else { return nil }
//            let encryptedData = try Data(contentsOf: url)
//            if encryptedData.isEmpty {
//                return .init()
//            } else {
//                return try? await getSymmetricKey().decrypt(encryptedData)
//            }
//        }
//
//        var icons = [FavIcon]()
//        for url in urls where url.pathExtension == "data" {
//            let hashedRootDomain = url.deletingPathExtension().lastPathComponent
//            let domainUrl = containerUrl.appendingPathComponent("\(hashedRootDomain).domain",
//                                                                conformingTo: .data)
//
//            if let domainData = try await getDecryptedData(domainUrl),
//               let decryptedImageData = try await getDecryptedData(url) {
//                let decryptedRootDomain = String(decoding: domainData, as: UTF8.self)
//                icons.append(.init(domain: decryptedRootDomain,
//                                   data: decryptedImageData,
//                                   isFromCache: true))
//            }
//        }
//
//        return icons.sorted(by: { $0.domain < $1.domain })
//    }
//
//    func emptyCache() throws {
//        guard FileManager.default.fileExists(atPath: containerUrl.path) else { return }
//        let urls = try FileManager.default.contentsOfDirectory(at: containerUrl,
//                                                               includingPropertiesForKeys: nil)
//        for url in urls {
//            try FileManager.default.removeItem(at: url)
//        }
//    }
// }
//
//// MARK: - Utils
//
// private extension FavIconRepository {
//    func fetchAndCacheIcon(for domain: String) async throws -> FavIcon? {
//        do {
//            let symmetricKey = try getSymmetricKey()
//
//            let domain = URL(string: domain)?.host ?? domain
//
//            let hashedDomain = domain.sha256
//            let dataUrl = containerUrl.appendingPathComponent("\(hashedDomain).data",
//                                                              conformingTo: .data)
//            if let encryptedData = try getDataOrRemoveIfObsolete(url: dataUrl),
//               let decryptedData = try? symmetricKey.decrypt(encryptedData) {
//                activeTasks[domain] = nil
//                return FavIcon(domain: domain, data: decryptedData, isFromCache: true)
//            }
//
//            if checkAndHandleCancellation(for: domain) { return nil }
//            let userId = try await userManager.getActiveUserId()
//            // Fav icon is not cached (or cached but is obsolete/deleted/not decryptable), fetch from remote
//            let result = try await datasource.fetchFavIcon(userId: userId, for: domain)
//
//            let dataToWrite: Data = switch result {
//            case let .positive(data):
//                data
//            case .negative:
//                .init()
//            }
//
//            // Create 2 files: 1 contains the actual data & 1 contains the encrypted root domain
//            try FileUtils.createOrOverwrite(data: symmetricKey.encrypt(dataToWrite),
//                                            fileName: "\(hashedDomain).data",
//                                            containerUrl: containerUrl)
//            guard let domainData = domain.data(using: .utf8) else {
//                throw PassError.crypto(.failedToEncode(domain))
//            }
//            try FileUtils.createOrOverwrite(data: symmetricKey.encrypt(domainData),
//                                            fileName: "\(hashedDomain).domain",
//                                            containerUrl: containerUrl)
//            return FavIcon(domain: domain, data: dataToWrite, isFromCache: false)
//        } catch {
//            activeTasks[domain] = nil
//            throw error
//        }
//    }
//
//    func getSymmetricKey() throws -> SymmetricKey {
//        try symmetricKeyProvider.getSymmetricKey()
//    }
//
//    func getDataOrRemoveIfObsolete(url: URL) throws -> Data? {
//        let isObsolete = FileUtils.isObsolete(url: url,
//                                              currentDate: .now,
//                                              thresholdInDays: cacheExpirationDays)
//        return try FileUtils.getDataRemovingIfObsolete(url: url, isObsolete: isObsolete)
//    }
// }
//
//// MARK: - Task Management
//
// private extension FavIconRepository {
//    func addActiveTask(_ task: Task<FavIcon?, any Error>, for domain: String) {
//        activeTasks[domain] = task
//    }
//
//    func cancelAndRemoveTask(for domain: String) {
//        activeTasks[domain]?.cancel()
//        activeTasks[domain] = nil
//    }
//
//    func checkAndHandleCancellation(for domain: String) -> Bool {
//        if Task.isCancelled {
//            cancelAndRemoveTask(for: domain)
//            return true
//        }
//        return false
//    }
// }
