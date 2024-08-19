//
//
// ToggleSentinel.swift
// Proton Pass - Created on 23/01/2024.
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

public protocol ToggleSentinelUseCase: Sendable {
    func execute() async throws -> Bool
}

public extension ToggleSentinelUseCase {
    func callAsFunction() async throws -> Bool {
        try await execute()
    }
}

public final class ToggleSentinel: ToggleSentinelUseCase {
    private let settingsService: any UserSettingsRepositoryProtocol
    private let userManager: any UserManagerProtocol

    public init(userSettingsProtocol: any UserSettingsRepositoryProtocol,
                userManager: any UserManagerProtocol) {
        settingsService = userSettingsProtocol
        self.userManager = userManager
    }

    public func execute() async throws -> Bool {
        let userId = try await userManager.getActiveUserId()
        try await settingsService.refreshSettings(for: userId)
        let userSettings = await settingsService.getSettings(for: userId)
        guard userSettings.highSecurity.eligible else {
            throw PassError.sentinelNotEligible
        }
        return try await settingsService.toggleSentinel(for: userId)
    }
}
