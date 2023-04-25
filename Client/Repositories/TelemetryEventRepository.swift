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
import ProtonCore_Login
import ProtonCore_Services

// MARK: - TelemetryEventRepositoryProtocol
public protocol TelemetryEventRepositoryProtocol {
    var localTelemetryEventDatasource: LocalTelemetryEventDatasourceProtocol { get }
    var remoteTelemetryEventDatasource: RemoteTelemetryEventDatasourceProtocol { get }
    var userPlanProvider: UserPlanProviderProtocol { get }
    var eventCount: Int { get }
    var logger: Logger { get }
    var scheduler: TelemetrySchedulerProtocol { get }
    var userId: String { get }

    func addNewEvent(type: TelemetryEventType) async throws

    /// - Returns: `true` if threshold is reached, `false` if threshold is not reached
    @discardableResult
    func sendAllEventsIfApplicable() async throws -> Bool
}

public extension TelemetryEventRepositoryProtocol {
    func addNewEvent(type: TelemetryEventType) async throws {
        try await localTelemetryEventDatasource.insert(event: .init(uuid: UUID().uuidString,
                                                                    time: Date.now.timeIntervalSince1970,
                                                                    type: type),
                                                       userId: userId)
        logger.debug("Added new event")
    }

    func sendAllEventsIfApplicable() async throws -> Bool {
        guard scheduler.shouldSendEvents() else {
            logger.trace("Threshold not reached")
            return false
        }

        logger.trace("Threshold is reached. Sending events if any.")
        logger.trace("Refreshing user plan")
        let userPlan = try await userPlanProvider.getUserPlan()

        while true {
            let events = try await localTelemetryEventDatasource.getOldestEvents(count: eventCount,
                                                                                 userId: userId)
            if events.isEmpty {
                break
            }
            let eventInfos = events.map { EventInfo(event: $0, userPlan: userPlan) }
            try await remoteTelemetryEventDatasource.send(events: eventInfos)
            try await localTelemetryEventDatasource.remove(events: events, userId: userId)
        }

        scheduler.randomNextThreshold()
        logger.info("Sent all events")
        return true
    }
}

public final class TelemetryEventRepository: TelemetryEventRepositoryProtocol {
    public let localTelemetryEventDatasource: LocalTelemetryEventDatasourceProtocol
    public let remoteTelemetryEventDatasource: RemoteTelemetryEventDatasourceProtocol
    public let userPlanProvider: UserPlanProviderProtocol
    public let eventCount: Int
    public let logger: Logger
    public let scheduler: TelemetrySchedulerProtocol
    public let userId: String

    public init(localTelemetryEventDatasource: LocalTelemetryEventDatasourceProtocol,
                remoteTelemetryEventDatasource: RemoteTelemetryEventDatasourceProtocol,
                userPlanProvider: UserPlanProviderProtocol,
                eventCount: Int,
                logManager: LogManager,
                scheduler: TelemetrySchedulerProtocol,
                userId: String) {
        self.localTelemetryEventDatasource = localTelemetryEventDatasource
        self.remoteTelemetryEventDatasource = remoteTelemetryEventDatasource
        self.userPlanProvider = userPlanProvider
        self.eventCount = eventCount
        self.logger = .init(manager: logManager)
        self.scheduler = scheduler
        self.userId = userId
    }
}

// MARK: - TelemetrySchedulerProtocol
public protocol TelemetrySchedulerProtocol: AnyObject {
    var currentDateProvider: CurrentDateProviderProtocol { get }
    var threshhold: Date? { get set }
    var minIntervalInHours: Int { get }
    var maxIntervalInHours: Int { get }

    func shouldSendEvents() -> Bool
    func randomNextThreshold()
}

public extension TelemetrySchedulerProtocol {
    func shouldSendEvents() -> Bool {
        let currentDate = currentDateProvider.getCurrentDate()
        if let threshhold {
            return currentDate > threshhold
        } else {
            return false
        }
    }

    func randomNextThreshold() {
        let randomIntervalInHours = Int.random(in: minIntervalInHours...maxIntervalInHours)
        let currentDate = currentDateProvider.getCurrentDate()
        threshhold = currentDate.adding(component: .hour, value: randomIntervalInHours)
    }
}

public final class TelemetryScheduler: TelemetrySchedulerProtocol {
    public let currentDateProvider: CurrentDateProviderProtocol
    public var threshhold: Date? {
        get {
            if let telemetryThreshold = preferences.telemetryThreshold {
                return Date(timeIntervalSince1970: telemetryThreshold)
            } else {
                return nil
            }
        }

        set {
            preferences.telemetryThreshold = newValue?.timeIntervalSince1970
        }
    }
    public let eventCount = 500
    public let minIntervalInHours = 6
    public let maxIntervalInHours = 12
    public let preferences: Preferences

    public init(currentDateProvider: CurrentDateProviderProtocol, preferences: Preferences) {
        self.currentDateProvider = currentDateProvider
        self.preferences = preferences
    }
}
