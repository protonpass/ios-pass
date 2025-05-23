//
//
// SendUserMonitoringStats.swift
// Proton Pass - Created on 17/12/2024.
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
import Core
import Foundation

public protocol SendUserMonitoringStatsUseCase: Sendable {
    func execute() async throws
}

public extension SendUserMonitoringStatsUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class SendUserMonitoringStats: SendUserMonitoringStatsUseCase {
    private let passMonitorRepository: any PassMonitorRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let userManager: any UserManagerProtocol
    private let storage: UserDefaults
    private let lastSentTimestampKey = "lastSentStatsTimestamp"
    private let waitingPeriodInHours: Int

    public init(passMonitorRepository: any PassMonitorRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol,
                userManager: any UserManagerProtocol,
                storage: UserDefaults,
                waitingPeriodInHours: Int = 24) {
        self.passMonitorRepository = passMonitorRepository
        self.accessRepository = accessRepository
        self.userManager = userManager
        self.storage = storage
        self.waitingPeriodInHours = waitingPeriodInHours
    }

    public func execute() async throws {
        guard thresholdReached else {
            return
        }
        let userId = try await userManager.getActiveUserId()
        let plan = try await accessRepository.getPlan(userId: userId)
        guard plan.planType == .business else { return }
        try await passMonitorRepository.sendUserMonitorStats()
        storeCurrentTimestamp()
    }
}

private extension SendUserMonitoringStats {
    func storeCurrentTimestamp() {
        let currentTime = Date()
        storage.set(currentTime, forKey: lastSentTimestampKey)
    }

    var thresholdReached: Bool {
        guard let lastSavedTime = storage.object(forKey: lastSentTimestampKey) as? Date else {
            return true // No timestamp found means stats never sent.
        }

        return Date().timeDifference(from: lastSavedTime).hours >= waitingPeriodInHours
    }
}
