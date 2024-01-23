//
//
// UpdateUserSettings.swift
// Proton Pass - Created on 22/01/2024.
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

public protocol UpdateUserSettingsUseCase: Sendable {
    func execute() async throws
}

public extension UpdateUserSettingsUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class UpdateUserSettings: UpdateUserSettingsUseCase {
    private let settingsService: any UserSettingsRepositoryProtocol
    private let repository: any RemoteUserSettingsDatasourceProtocol

    public init(userSettingsProtocol: any UserSettingsRepositoryProtocol,
                repository: any RemoteUserSettingsDatasourceProtocol) {
        self.repository = repository
        settingsService = userSettingsProtocol
    }

    public func execute() async throws {
        let settings = try await repository.getUserSettings()
        await settingsService.updateSettings(settings: settings)
    }
}
