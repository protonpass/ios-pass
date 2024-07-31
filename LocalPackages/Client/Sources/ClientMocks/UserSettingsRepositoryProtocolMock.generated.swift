// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
// Copyright (c) 2023 Proton Technologies AG
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

import Client
import Foundation

public final class UserSettingsRepositoryProtocolMock: @unchecked Sendable, UserSettingsRepositoryProtocol {

    public init() {}

    // MARK: - getSettings
    public var closureGetSettings: () -> () = {}
    public var invokedGetSettingsfunction = false
    public var invokedGetSettingsCount = 0
    public var invokedGetSettingsParameters: (id: String, Void)?
    public var invokedGetSettingsParametersList = [(id: String, Void)]()
    public var stubbedGetSettingsResult: UserSettings!

    public func getSettings(for id: String) async -> UserSettings {
        invokedGetSettingsfunction = true
        invokedGetSettingsCount += 1
        invokedGetSettingsParameters = (id, ())
        invokedGetSettingsParametersList.append((id, ()))
        closureGetSettings()
        return stubbedGetSettingsResult
    }
    // MARK: - refreshSettings
    public var refreshSettingsForThrowableError2: Error?
    public var closureRefreshSettings: () -> () = {}
    public var invokedRefreshSettingsfunction = false
    public var invokedRefreshSettingsCount = 0
    public var invokedRefreshSettingsParameters: (id: String, Void)?
    public var invokedRefreshSettingsParametersList = [(id: String, Void)]()

    public func refreshSettings(for id: String) async throws {
        invokedRefreshSettingsfunction = true
        invokedRefreshSettingsCount += 1
        invokedRefreshSettingsParameters = (id, ())
        invokedRefreshSettingsParametersList.append((id, ()))
        if let error = refreshSettingsForThrowableError2 {
            throw error
        }
        closureRefreshSettings()
    }
    // MARK: - toggleSentinel
    public var toggleSentinelForThrowableError3: Error?
    public var closureToggleSentinel: () -> () = {}
    public var invokedToggleSentinelfunction = false
    public var invokedToggleSentinelCount = 0
    public var invokedToggleSentinelParameters: (id: String, Void)?
    public var invokedToggleSentinelParametersList = [(id: String, Void)]()
    public var stubbedToggleSentinelResult: Bool!

    public func toggleSentinel(for id: String) async throws -> Bool {
        invokedToggleSentinelfunction = true
        invokedToggleSentinelCount += 1
        invokedToggleSentinelParameters = (id, ())
        invokedToggleSentinelParametersList.append((id, ()))
        if let error = toggleSentinelForThrowableError3 {
            throw error
        }
        closureToggleSentinel()
        return stubbedToggleSentinelResult
    }
}
