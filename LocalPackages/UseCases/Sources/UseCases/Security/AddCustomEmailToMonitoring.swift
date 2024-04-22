//
//
// AddCustomEmailToMonitoring.swift
// Proton Pass - Created on 19/04/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Client
import Entities

public protocol AddCustomEmailToMonitoringUseCase: Sendable {
    func execute(email: String) async throws -> CustomEmail
}

public extension AddCustomEmailToMonitoringUseCase {
    func callAsFunction(email: String) async throws -> CustomEmail {
        try await execute(email: email)
    }
}

public final class AddCustomEmailToMonitoring: AddCustomEmailToMonitoringUseCase {
    private let repository: any PassMonitorRepositoryProtocol
    private let stream: DarkWebSectionUpdateStream

    public init(repository: any PassMonitorRepositoryProtocol,
                stream: DarkWebSectionUpdateStream) {
        self.repository = repository
        self.stream = stream
    }

    public func execute(email: String) async throws -> CustomEmail {
        let email = try await repository.addEmailToBreachMonitoring(email: email)
        let emails = try await repository.getAllCustomEmailForUser()
        stream.send(.customEmails(emails))
        return email
    }
}
