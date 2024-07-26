//
//
// GetSentinelStatus.swift
// Proton Pass - Created on 09/04/2024.
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

public protocol GetSentinelStatusUseCase: Sendable {
    func execute() async -> Bool
}

public extension GetSentinelStatusUseCase {
    func callAsFunction() async -> Bool {
        await execute()
    }
}

public final class GetSentinelStatus: GetSentinelStatusUseCase {
    private let settingsService: any UserSettingsRepositoryProtocol
    private let userManager: any UserManagerProtocol

    public init(userSettingsProtocol: any UserSettingsRepositoryProtocol,
                userManager: any UserManagerProtocol) {
        settingsService = userSettingsProtocol
        self.userManager = userManager
    }

    public func execute() async -> Bool {
        guard let userId = try? await userManager.getActiveUserId() else {
            return false
        }
        let settings = await settingsService.getSettings(for: userId)
        return settings.highSecurity.value
    }
}
