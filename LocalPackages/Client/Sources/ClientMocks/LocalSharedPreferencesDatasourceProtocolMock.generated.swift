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
import Core
import Entities
import Foundation

public final class LocalSharedPreferencesDatasourceProtocolMock: @unchecked Sendable, LocalSharedPreferencesDatasourceProtocol {

    public init() {}

    // MARK: - getPreferences
    public var getPreferencesThrowableError1: Error?
    public var closureGetPreferences: () -> () = {}
    public var invokedGetPreferencesfunction = false
    public var invokedGetPreferencesCount = 0
    public var stubbedGetPreferencesResult: SharedPreferences?

    public func getPreferences() async throws -> SharedPreferences? {
        invokedGetPreferencesfunction = true
        invokedGetPreferencesCount += 1
        if let error = getPreferencesThrowableError1 {
            throw error
        }
        closureGetPreferences()
        return stubbedGetPreferencesResult
    }
    // MARK: - upsertPreferences
    public var upsertPreferencesThrowableError2: Error?
    public var closureUpsertPreferences: () -> () = {}
    public var invokedUpsertPreferencesfunction = false
    public var invokedUpsertPreferencesCount = 0
    public var invokedUpsertPreferencesParameters: (preferences: SharedPreferences, Void)?
    public var invokedUpsertPreferencesParametersList = [(preferences: SharedPreferences, Void)]()

    public func upsertPreferences(_ preferences: SharedPreferences) async throws {
        invokedUpsertPreferencesfunction = true
        invokedUpsertPreferencesCount += 1
        invokedUpsertPreferencesParameters = (preferences, ())
        invokedUpsertPreferencesParametersList.append((preferences, ()))
        if let error = upsertPreferencesThrowableError2 {
            throw error
        }
        closureUpsertPreferences()
    }
    // MARK: - removePreferences
    public var removePreferencesThrowableError3: Error?
    public var closureRemovePreferences: () -> () = {}
    public var invokedRemovePreferencesfunction = false
    public var invokedRemovePreferencesCount = 0

    public func removePreferences() throws {
        invokedRemovePreferencesfunction = true
        invokedRemovePreferencesCount += 1
        if let error = removePreferencesThrowableError3 {
            throw error
        }
        closureRemovePreferences()
    }
}
