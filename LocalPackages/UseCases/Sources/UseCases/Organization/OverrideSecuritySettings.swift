//
// OverrideSecuritySettings.swift
// Proton Pass - Created on 19/03/2024.
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

public protocol OverrideSecuritySettingsUseCase: Sendable {
    func execute(with organization: Organization) async throws
}

public extension OverrideSecuritySettingsUseCase {
    func callAsFunction(with organization: Organization) async throws {
        try await execute(with: organization)
    }
}

public final class OverrideSecuritySettings: OverrideSecuritySettingsUseCase {
    private let preferencesManager: any PreferencesManagerProtocol

    public init(preferencesManager: any PreferencesManagerProtocol) {
        self.preferencesManager = preferencesManager
    }

    public func execute(with organization: Organization) async throws {
        guard let appLockTime = organization.settings.appLockTime else { return }
        try await preferencesManager.updateSharedPreferences(\.appLockTime, value: appLockTime)

        // Only default to biometric authentication if user has no authentication method
        if preferencesManager.sharedPreferences.unwrapped().localAuthenticationMethod == .none {
            try await preferencesManager.updateSharedPreferences(\.localAuthenticationMethod,
                                                                 value: .biometric)
        }
    }
}
