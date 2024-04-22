//
// RefreshAccessAndMonitorState.swift
// Proton Pass - Created on 22/04/2024.
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
import Foundation

public protocol RefreshAccessAndMonitorStateUseCase: Sendable {
    func execute() async throws
}

public extension RefreshAccessAndMonitorStateUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class RefreshAccessAndMonitorState: RefreshAccessAndMonitorStateUseCase {
    private let accessRepository: any AccessRepositoryProtocol
    private let passMonitorRepository: any PassMonitorRepositoryProtocol
    private let stream: MonitorStateStream

    public init(accessRepository: any AccessRepositoryProtocol,
                passMonitorRepository: any PassMonitorRepositoryProtocol,
                stream: MonitorStateStream) {
        self.accessRepository = accessRepository
        self.passMonitorRepository = passMonitorRepository
        self.stream = stream
    }

    public func execute() async throws {
        async let getAccess = accessRepository.refreshAccess()
        async let refreshUserBreaches = passMonitorRepository.refreshUserBreaches()
        async let refreshSecurityChecks: () = passMonitorRepository.refreshSecurityChecks()
        let (access, userBreaches, _) = try await (getAccess, refreshUserBreaches, refreshSecurityChecks)
        let hasWeaknesses = passMonitorRepository.weaknessStats.value.hasWeakOrReusedPasswords

        let state = switch (access.plan.isFreeUser, userBreaches.breached, hasWeaknesses) {
        case (true, false, false):
            MonitorState.inactive(.noBreaches)
        case (true, false, true):
            MonitorState.inactive(.noBreachesButWeakOrReusedPasswords)
        case (true, true, _):
            MonitorState.inactive(.breachesFound)
        case (false, false, false):
            MonitorState.active(.noBreaches)
        case (false, false, true):
            MonitorState.active(.noBreachesButWeakOrReusedPasswords)
        case (false, true, _):
            MonitorState.active(.breachesFound)
        }
        stream.send(state)
    }
}
