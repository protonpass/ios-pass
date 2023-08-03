//
// AddTelemetryEvent.swift
// Proton Pass - Created on 02/08/2023.
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

import Client
import Core

protocol AddTelemetryEventUseCase: Sendable {
    func execute(with repository: TelemetryEventRepositoryProtocol, eventType: TelemetryEventType)
}

extension AddTelemetryEventUseCase {
    func callAsFunction(with repository: TelemetryEventRepositoryProtocol,
                        eventType: TelemetryEventType) {
        execute(with: repository, eventType: eventType)
    }
}

final class AddTelemetryEvent: @unchecked Sendable, AddTelemetryEventUseCase {
    private let logger: Logger

    init(logManager: LogManagerProtocol) {
        logger = .init(manager: logManager)
    }

    func execute(with repository: TelemetryEventRepositoryProtocol, eventType: TelemetryEventType) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await repository.addNewEvent(type: eventType)
            } catch {
                self.logger.error(error)
            }
        }
    }
}
