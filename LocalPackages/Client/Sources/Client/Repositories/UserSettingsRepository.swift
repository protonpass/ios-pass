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
    func getSettings(for id: String) async -> UserSettings
    func refreshSettings(for id: String) async throws
    func toggleSentinel(for id: String) async throws
}

public actor UserSettingsRepository: UserSettingsRepositoryProtocol {
    private let userDefaultService: any UserDefaultPersistency
    private let remoteDatasource: any RemoteUserSettingsDatasourceProtocol

    public init(userDefaultService: any UserDefaultPersistency,
                remoteDatasource: any RemoteUserSettingsDatasourceProtocol) {
        self.userDefaultService = userDefaultService
        self.remoteDatasource = remoteDatasource
    }

    public func getSettings(for id: String) async -> UserSettings {
        guard let data: Data = userDefaultService.value(forKey: UserDefaultsKey.settings, and: id),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data) else {
            return UserSettings.default
        }
        return settings
    }

    public func refreshSettings(for id: String) async throws {
        let settings = try await remoteDatasource.getUserSettings()
        updateSettings(settings: settings, and: id)
    }

    public func toggleSentinel(for id: String) async throws {
        let settings = try await remoteDatasource.getUserSettings()
        if settings.highSecurity.value {
            try await remoteDatasource.desactivateSentinel()
        } else {
            try await remoteDatasource.activateSentinel()
        }
        try await refreshSettings(for: id)
    }
}

private extension UserSettingsRepository {
    func updateSettings(settings: UserSettings, and id: String) {
        do {
            let encodedSettings = try JSONEncoder().encode(settings)
            try userDefaultService.set(value: encodedSettings, forKey: UserDefaultsKey.settings, and: id)
        } catch {
            print(error.localizedDescription)
        }
    }
}
