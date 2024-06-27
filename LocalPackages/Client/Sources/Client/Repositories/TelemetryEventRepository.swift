//
// TelemetryEventRepository.swift
// Proton Pass - Created on 24/04/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import Core
import Entities
import Foundation

public enum TelemetryEventSendResult: Sendable {
    case thresholdNotReached
    case thresholdReachedButTelemetryOff
    case allEventsSent
}

// MARK: - TelemetryEventRepositoryProtocol

public protocol TelemetryEventRepositoryProtocol: Sendable {
    var scheduler: any TelemetrySchedulerProtocol { get }

    func getAllEvents(userId: String) async throws -> [TelemetryEvent]

    func addNewEvent(type: TelemetryEventType) async throws

    @discardableResult
    func sendAllEventsIfApplicable() async throws -> TelemetryEventSendResult
}

public actor TelemetryEventRepository: TelemetryEventRepositoryProtocol {
    private let localDatasource: any LocalTelemetryEventDatasourceProtocol
    private let remoteDatasource: any RemoteTelemetryEventDatasourceProtocol
    private let userSettingsRepository: any UserSettingsRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let itemReadEventRepository: any ItemReadEventRepositoryProtocol
    private let batchSize: Int
    private let logger: Logger
    public let scheduler: any TelemetrySchedulerProtocol
    private let userManager: any UserManagerProtocol

    public init(localDatasource: any LocalTelemetryEventDatasourceProtocol,
                remoteDatasource: any RemoteTelemetryEventDatasourceProtocol,
                userSettingsRepository: any UserSettingsRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol,
                itemReadEventRepository: any ItemReadEventRepositoryProtocol,
                logManager: any LogManagerProtocol,
                scheduler: any TelemetrySchedulerProtocol,
                userManager: any UserManagerProtocol,
                batchSize: Int = Constants.Utils.batchSize) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.userSettingsRepository = userSettingsRepository
        self.accessRepository = accessRepository
        self.itemReadEventRepository = itemReadEventRepository
        self.batchSize = batchSize
        logger = .init(manager: logManager)
        self.scheduler = scheduler
        self.userManager = userManager
    }
}

public extension TelemetryEventRepository {
    func getAllEvents(userId: String) async throws -> [TelemetryEvent] {
        try await localDatasource.getAllEvents(userId: userId)
    }

    func addNewEvent(type: TelemetryEventType) async throws {
        let userId = try await userManager.getActiveUserId()
        try await localDatasource.insert(event: .init(uuid: UUID().uuidString,
                                                      time: Date.now.timeIntervalSince1970,
                                                      type: type),
                                         userId: userId)
        logger.debug("Added new event")
    }

    func sendAllEventsIfApplicable() async throws -> TelemetryEventSendResult {
        guard try await scheduler.shouldSendEvents() else {
            logger.debug("Threshold not reached")
            return .thresholdNotReached
        }

        let userId = try await userManager.getActiveUserId()

        logger.debug("Threshold is reached. Checking telemetry settings before sending events.")

        let telemetry = await userSettingsRepository.getSettings(for: userId).telemetry

        logger.trace("Refreshing user access")
        let plan = try await accessRepository.refreshAccess().plan

        try await sendAllItemReadEvents(plan: plan)

        if !telemetry {
            logger.info("Telemetry disabled, removing all local events.")
            try await localDatasource.removeAllEvents(userId: userId)
            try await scheduler.randomNextThreshold()
            return .thresholdReachedButTelemetryOff
        }

        try await sendAllTelemetryEvents(userId: userId, plan: plan)

        logger.info("Sent all events")
        try await scheduler.randomNextThreshold()
        return .allEventsSent
    }

    /// For testing purpose only. Not available at protocol level.
    func forceSendAllEvents() async throws {
        logger.debug("Force sending all events")
        let userId = try await userManager.getActiveUserId()
        let plan = try await accessRepository.refreshAccess().plan
        try await sendAllItemReadEvents(plan: plan)
        try await sendAllTelemetryEvents(userId: userId, plan: plan)
        logger.info("Force sent all events")
    }
}

private extension TelemetryEventRepository {
    func sendAllItemReadEvents(plan: Plan) async throws {
        if plan.isBusinessUser {
            logger.trace("[B2B] Ignore telemetry settings and send read events")
            try await itemReadEventRepository.sendAllEvents()
        }
    }

    func sendAllTelemetryEvents(userId: String, plan: Plan) async throws {
        while true {
            let events = try await localDatasource.getOldestEvents(count: batchSize,
                                                                   userId: userId)
            if events.isEmpty {
                break
            }
            let eventInfos = events.map { EventInfo(event: $0, userTier: plan.internalName) }
            try await remoteDatasource.send(events: eventInfos)
            try await localDatasource.remove(events: events, userId: userId)
        }
    }
}

// MARK: - TelemetrySchedulerProtocol

public protocol TelemetrySchedulerProtocol: Actor, Sendable {
    func shouldSendEvents() async throws -> Bool
    func randomNextThreshold() async throws
    func getThreshold() -> Date?
}

public actor TelemetryScheduler: TelemetrySchedulerProtocol {
    public let currentDateProvider: any CurrentDateProviderProtocol
    public let minIntervalInHours = 6
    public let maxIntervalInHours = 12
    public let thresholdProvider: any TelemetryThresholdProviderProtocol

    public init(currentDateProvider: any CurrentDateProviderProtocol,
                thresholdProvider: any TelemetryThresholdProviderProtocol) {
        self.currentDateProvider = currentDateProvider
        self.thresholdProvider = thresholdProvider
    }

    public func getThreshold() -> Date? {
        if let telemetryThreshold = thresholdProvider.getThreshold() {
            Date(timeIntervalSince1970: telemetryThreshold)
        } else {
            nil
        }
    }

    func setThreshold(with date: Date?) async throws {
        try await thresholdProvider.setThreshold(date?.timeIntervalSince1970)
    }

    public func shouldSendEvents() async throws -> Bool {
        let currentDate = currentDateProvider.getCurrentDate()
        if let threshold = thresholdProvider.getThreshold() {
            return currentDate > Date(timeIntervalSince1970: threshold)
        } else {
            try await randomNextThreshold()
            return false
        }
    }

    public func randomNextThreshold() async throws {
        let randomIntervalInHours = Int.random(in: minIntervalInHours...maxIntervalInHours)
        let currentDate = currentDateProvider.getCurrentDate()
        try await setThreshold(with: currentDate.adding(component: .hour, value: randomIntervalInHours))
    }
}

public protocol TelemetryThresholdProviderProtocol: Sendable {
    func getThreshold() -> TimeInterval?
    func setThreshold(_ threshold: TimeInterval?) async throws
}
