//
// SendTelemetryEvent.swift
// Proton Pass - Created on 14/02/2025.
// Copyright (c) 2025 Proton Technologies AG
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
//

// periphery:ignore:all
import Client
import Core
import Entities
import Foundation

/// Send events for unauthenticated sessions
public protocol SendTelemetryEventUseCase: Sendable {
    func execute(_ eventType: TelemetryEventType)
}

public extension SendTelemetryEventUseCase {
    func callAsFunction(_ eventType: TelemetryEventType) {
        execute(eventType)
    }
}

public final class SendTelemetryEvent: SendTelemetryEventUseCase {
    private let datasource: any RemoteTelemetryEventDatasourceProtocol
    private let logger: Logger

    public init(datasource: any RemoteTelemetryEventDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.datasource = datasource
        logger = .init(manager: logManager)
    }

    public func execute(_ eventType: TelemetryEventType) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let event = TelemetryEvent(uuid: UUID().uuidString,
                                           time: Date.now.timeIntervalSince1970,
                                           type: eventType)
                try await datasource.send(events: [.init(event: event, userTier: nil)])
            } catch {
                logger.error(error)
            }
        }
    }
}
