//
// LocalAppPreferencesDatasource.swift
// Proton Pass - Created on 03/04/2024.
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

// swiftlint:disable:next todo
// TODO: remove periphery ignore
// periphery:ignore:all
import Entities
import Foundation

private let kAppPreferencesKey = "AppPreferences"

/// Store `AppPreferences` as-is in `UserDefaults`
public protocol LocalAppPreferencesDatasourceProtocol: Sendable {
    func getPreferences() throws -> AppPreferences?
    func upsertPreferences(_ preferences: AppPreferences) throws
    func removePreferences()
}

public final class LocalAppPreferencesDatasource: LocalAppPreferencesDatasourceProtocol {
    private let userDefault: UserDefaults

    public init(userDefault: UserDefaults) {
        self.userDefault = userDefault
    }
}

public extension LocalAppPreferencesDatasource {
    func getPreferences() throws -> AppPreferences? {
        guard let data = userDefault.data(forKey: kAppPreferencesKey) else {
            return nil
        }
        return try JSONDecoder().decode(AppPreferences.self, from: data)
    }

    func upsertPreferences(_ preferences: AppPreferences) throws {
        let data = try JSONEncoder().encode(preferences)
        userDefault.set(data, forKey: kAppPreferencesKey)
    }

    func removePreferences() {
        userDefault.removeObject(forKey: kAppPreferencesKey)
    }
}
