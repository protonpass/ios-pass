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
import CoreData
import CryptoKit
import Entities
import Foundation

public final class LocalUserPreferencesDatasourceProtocolMock: @unchecked Sendable, LocalUserPreferencesDatasourceProtocol {

    public init() {}

    // MARK: - getPreferences
    public var getPreferencesForThrowableError1: Error?
    public var closureGetPreferences: () -> () = {}
    public var invokedGetPreferencesfunction = false
    public var invokedGetPreferencesCount = 0
    public var invokedGetPreferencesParameters: (userId: String, Void)?
    public var invokedGetPreferencesParametersList = [(userId: String, Void)]()
    public var stubbedGetPreferencesResult: UserPreferences?

    public func getPreferences(for userId: String) async throws -> UserPreferences? {
        invokedGetPreferencesfunction = true
        invokedGetPreferencesCount += 1
        invokedGetPreferencesParameters = (userId, ())
        invokedGetPreferencesParametersList.append((userId, ()))
        if let error = getPreferencesForThrowableError1 {
            throw error
        }
        closureGetPreferences()
        return stubbedGetPreferencesResult
    }
    // MARK: - upsertPreferences
    public var upsertPreferencesForThrowableError2: Error?
    public var closureUpsertPreferences: () -> () = {}
    public var invokedUpsertPreferencesfunction = false
    public var invokedUpsertPreferencesCount = 0
    public var invokedUpsertPreferencesParameters: (preferences: UserPreferences, userId: String)?
    public var invokedUpsertPreferencesParametersList = [(preferences: UserPreferences, userId: String)]()

    public func upsertPreferences(_ preferences: UserPreferences, for userId: String) async throws {
        invokedUpsertPreferencesfunction = true
        invokedUpsertPreferencesCount += 1
        invokedUpsertPreferencesParameters = (preferences, userId)
        invokedUpsertPreferencesParametersList.append((preferences, userId))
        if let error = upsertPreferencesForThrowableError2 {
            throw error
        }
        closureUpsertPreferences()
    }
    // MARK: - removePreferences
    public var removePreferencesForThrowableError3: Error?
    public var closureRemovePreferences: () -> () = {}
    public var invokedRemovePreferencesfunction = false
    public var invokedRemovePreferencesCount = 0
    public var invokedRemovePreferencesParameters: (userId: String, Void)?
    public var invokedRemovePreferencesParametersList = [(userId: String, Void)]()

    public func removePreferences(for userId: String) async throws {
        invokedRemovePreferencesfunction = true
        invokedRemovePreferencesCount += 1
        invokedRemovePreferencesParameters = (userId, ())
        invokedRemovePreferencesParametersList.append((userId, ()))
        if let error = removePreferencesForThrowableError3 {
            throw error
        }
        closureRemovePreferences()
    }
    // MARK: - removeAllPreferences
    public var removeAllPreferencesThrowableError4: Error?
    public var closureRemoveAllPreferences: () -> () = {}
    public var invokedRemoveAllPreferencesfunction = false
    public var invokedRemoveAllPreferencesCount = 0

    public func removeAllPreferences() async throws {
        invokedRemoveAllPreferencesfunction = true
        invokedRemoveAllPreferencesCount += 1
        if let error = removeAllPreferencesThrowableError4 {
            throw error
        }
        closureRemoveAllPreferences()
    }
}
