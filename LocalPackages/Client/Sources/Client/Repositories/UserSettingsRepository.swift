//
// UserSettingsRepository.swift
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

import Foundation

public protocol UserSettingsRepositoryProtocol: Sendable {
    func getSettings() async -> UserSettings
    func updateSettings(settings: UserSettings) async
    func updateSettings() async throws
    func toggleSentinel() async throws
}

public actor UserSettingsRepository: UserSettingsRepositoryProtocol {
    private let userDefaultService: any UserDefaultPersistency
    private let repository: any RemoteUserSettingsDatasourceProtocol

    public init(userDefaultService: any UserDefaultPersistency,
                repository: any RemoteUserSettingsDatasourceProtocol) {
        self.userDefaultService = userDefaultService
        self.repository = repository
    }

    public func getSettings() async -> UserSettings {
        guard let data: Data = userDefaultService.value(forKey: UserDefaultsKey.settings),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings.default
        }
        return settings
    }

    public func updateSettings(settings: UserSettings) {
        do {
            let encodedSettings = try JSONEncoder().encode(settings)
            try userDefaultService.set(value: encodedSettings, forKey: UserDefaultsKey.settings)
        } catch {
            print(error.localizedDescription)
        }
    }

    public func updateSettings() async throws {
        let settings = try await repository.getUserSettings()
        updateSettings(settings: settings)
    }

    public func toggleSentinel() async throws {
        let settings = await getSettings()
        if settings.highSecurity.value {
            try await repository.desactivateSentinel()
        } else {
            try await repository.activateSentinel()
        }
        try await updateSettings()
    }
}
