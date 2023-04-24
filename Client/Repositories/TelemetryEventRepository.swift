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

public protocol TelemetryEventRepositoryProtocol {
    var localTelemetryEventDatasource: LocalTelemetryEventDatasourceProtocol { get }
    var remoteTelemetryEventDatasource: RemoteTelemetryEventDatasourceProtocol { get }
    var logger: Logger { get }

    func addNewEvent(type: TelemetryEventType) async throws
    func sendAllEventsIfApplicable() async throws
}

extension TelemetryEventRepositoryProtocol {
    func addNewEvent(type: TelemetryEventType) async throws {
        try await localTelemetryEventDatasource.insert(event: .init(uuid: UUID().uuidString, type: type))
        logger.debug("Added new event")
    }

    func sendAllEventsIfApplicable() async throws {
        let eventCount = 100
        while true {
            let events = try await localTelemetryEventDatasource.getOldestEvents(count: eventCount)
            if events.isEmpty {
                break
            }
            let eventInfos = events.map { EventInfo(event: $0, planName: "free") }
            try await remoteTelemetryEventDatasource.send(events: eventInfos)
        }
    }
}
