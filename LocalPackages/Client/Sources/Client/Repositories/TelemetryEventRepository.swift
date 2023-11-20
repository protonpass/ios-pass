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
import ProtonCoreLogin
import ProtonCoreServices

public enum TelemetryEventSendResult {
    case thresholdNotReached
    case thresholdReachedButTelemetryOff
    case allEventsSent
}

// MARK: - TelemetryEventRepositoryProtocol

public protocol TelemetryEventRepositoryProtocol {
    var scheduler: TelemetrySchedulerProtocol { get }

    func getAllEvents(userId: String) async throws -> [TelemetryEvent]

    func addNewEvent(type: TelemetryEventType) async throws

    @discardableResult
    func sendAllEventsIfApplicable() async throws -> TelemetryEventSendResult
}

public actor TelemetryEventRepository: TelemetryEventRepositoryProtocol {
    public let localDatasource: LocalTelemetryEventDatasourceProtocol
    public let remoteDatasource: RemoteTelemetryEventDatasourceProtocol
    public let remoteUserSettingsDatasource: RemoteUserSettingsDatasourceProtocol
    public let accessRepository: AccessRepositoryProtocol
    public let eventCount: Int
    public let logger: Logger
    public let scheduler: TelemetrySchedulerProtocol
    public let userDataProvider: UserDataProvider

    public init(localDatasource: LocalTelemetryEventDatasourceProtocol,
                remoteDatasource: RemoteTelemetryEventDatasourceProtocol,
                remoteUserSettingsDatasource: RemoteUserSettingsDatasourceProtocol,
                accessRepository: AccessRepositoryProtocol,
                logManager: LogManagerProtocol,
                scheduler: TelemetrySchedulerProtocol,
                userDataProvider: UserDataProvider,
                eventCount: Int = 500) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.remoteUserSettingsDatasource = remoteUserSettingsDatasource
        self.accessRepository = accessRepository
        self.eventCount = eventCount
        logger = .init(manager: logManager)
        self.scheduler = scheduler
        self.userDataProvider = userDataProvider
    }
}

public extension TelemetryEventRepository {
    func getAllEvents(userId: String) async throws -> [TelemetryEvent] {
        try await localDatasource.getAllEvents(userId: userId)
    }

    func addNewEvent(type: TelemetryEventType) async throws {
        let userId = try userDataProvider.getUserId()
        try await localDatasource.insert(event: .init(uuid: UUID().uuidString,
                                                      time: Date.now.timeIntervalSince1970,
                                                      type: type),
                                         userId: userId)
        logger.debug("Added new event")
    }

    func sendAllEventsIfApplicable() async throws -> TelemetryEventSendResult {
        guard scheduler.shouldSendEvents() else {
            logger.debug("Threshold not reached")
            return .thresholdNotReached
        }

        defer { scheduler.randomNextThreshold() }

        let userId = try userDataProvider.getUserId()

        logger.debug("Threshold is reached. Checking telemetry settings before sending events.")

        let userSettings = try await remoteUserSettingsDatasource.getUserSettings()

        if !userSettings.telemetry {
            logger.info("Telemetry disabled, removing all local events.")
            try await localDatasource.removeAllEvents(userId: userId)
            return .thresholdReachedButTelemetryOff
        }

        logger.trace("Telemetry enabled, refreshing user access.")
        let plan = try await accessRepository.refreshAccess().plan

        while true {
            let events = try await localDatasource.getOldestEvents(count: eventCount,
                                                                   userId: userId)
            if events.isEmpty {
                break
            }
            let eventInfos = events.map { EventInfo(event: $0, userTier: plan.internalName) }
            try await remoteDatasource.send(events: eventInfos)
            try await localDatasource.remove(events: events, userId: userId)
        }

        logger.info("Sent all events")
        return .allEventsSent
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
            randomNextThreshold()
            return false
        }
    }

    /// We are setting this function as part of the main actor as it has influence on Preference that seems to
    /// trigger an ui update.
    /// We saw crash as the update what not executed from the main thread.
    /// This is an attend to mitigate this issue
    @MainActor
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
            if let telemetryThreshold = thresholdProvider.getThreshold() {
                return Date(timeIntervalSince1970: telemetryThreshold)
            } else {
                return nil
            }
        }

        set {
            thresholdProvider.setThreshold(newValue?.timeIntervalSince1970)
        }
    }

    public let eventCount = 500
    public let minIntervalInHours = 6
    public let maxIntervalInHours = 12
    public let thresholdProvider: TelemetryThresholdProviderProtocol

    public init(currentDateProvider: CurrentDateProviderProtocol,
                thresholdProvider: TelemetryThresholdProviderProtocol) {
        self.currentDateProvider = currentDateProvider
        self.thresholdProvider = thresholdProvider
    }
}

public protocol TelemetryThresholdProviderProtocol {
    func getThreshold() -> TimeInterval?
    func setThreshold(_ threshold: TimeInterval?)
}
