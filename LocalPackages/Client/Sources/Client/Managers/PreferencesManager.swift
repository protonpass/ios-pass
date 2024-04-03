//
// PreferencesManager.swift
// Proton Pass - Created on 29/03/2024.
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
@preconcurrency import Combine
import Core
import Entities
import Foundation

/// Should not deal with this object directly from the outside
/// but use `filter` operator to parse and filter updates
public struct PreferencesUpdate<T>: @unchecked Sendable {
    public let keyPath: PartialKeyPath<T>
    public let value: any Sendable
}

public typealias UserPreferencesUpdate = PreferencesUpdate<UserPreferences>
public typealias SharedPreferencesUpdate = PreferencesUpdate<SharedPreferences>

/// Manage app-wide preferences and current user's ones
public protocol PreferencesManagerProtocol {
    var userPreferences: CurrentValueSubject<UserPreferences?, Never> { get }
    var userPreferencesUpdates: PassthroughSubject<UserPreferencesUpdate, Never> { get }

    var sharedPreferences: CurrentValueSubject<SharedPreferences?, Never> { get }
    var sharedPreferencesUpdates: PassthroughSubject<SharedPreferencesUpdate, Never> { get }

    /// Load preferences or create with default values if not exist
    func setUp() async throws

    func updateUserPreferences<T: Sendable>(_ keyPath: WritableKeyPath<UserPreferences, T>,
                                            value: T) async throws
    func removeUserPreferences() async throws

    func updateSharedPreferences<T: Sendable>(_ keyPath: WritableKeyPath<SharedPreferences, T>,
                                              value: T) async throws
    func removeSharedPreferences() async throws
}

public actor PreferencesManager: PreferencesManagerProtocol {
    public nonisolated let userPreferences = CurrentValueSubject<UserPreferences?, Never>(nil)
    public nonisolated let userPreferencesUpdates = PassthroughSubject<UserPreferencesUpdate, Never>()

    public nonisolated let sharedPreferences = CurrentValueSubject<SharedPreferences?, Never>(nil)
    public nonisolated let sharedPreferencesUpdates = PassthroughSubject<SharedPreferencesUpdate, Never>()

    private let sharedPreferencesDatasource: any LocalSharedPreferencesDatasourceProtocol
    private let userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol
    // swiftlint:disable:next todo
    // TODO: Inject via a protocol
    private let userId: String

    private var didSetUp = false

    public init(userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol,
                sharedPreferencesDatasource: any LocalSharedPreferencesDatasourceProtocol,
                userId: String = "") {
        self.userPreferencesDatasource = userPreferencesDatasource
        self.sharedPreferencesDatasource = sharedPreferencesDatasource
        self.userId = userId
    }
}

public extension PreferencesManager {
    func setUp() async throws {
        // Shared preferences
        if let preferences = try sharedPreferencesDatasource.getPreferences() {
            sharedPreferences.send(preferences)
        } else {
            let preferences = SharedPreferences.default
            try sharedPreferencesDatasource.upsertPreferences(preferences)
            sharedPreferences.send(preferences)
        }

        // User's preferences
        if let preferences = try await userPreferencesDatasource.getPreferences(for: userId) {
            userPreferences.send(preferences)
        } else {
            let preferences = UserPreferences.default
            try await userPreferencesDatasource.upsertPreferences(preferences, for: userId)
            userPreferences.send(preferences)
        }

        didSetUp = true
    }

    func updateUserPreferences<T: Sendable>(_ keyPath: WritableKeyPath<UserPreferences, T>,
                                            value: T) async throws {
        guard assertDidSetUp(),
              var preferences = userPreferences.value else {
            return
        }
        preferences[keyPath: keyPath] = value
        try await userPreferencesDatasource.upsertPreferences(preferences, for: userId)
        userPreferences.send(preferences)
        userPreferencesUpdates.send(.init(keyPath: keyPath, value: value))
    }

    func removeUserPreferences() async throws {
        try await userPreferencesDatasource.removePreferences(for: userId)
    }

    func updateSharedPreferences<T: Sendable>(_ keyPath: WritableKeyPath<SharedPreferences, T>,
                                              value: T) async throws {
        guard assertDidSetUp(),
              var preferences = sharedPreferences.value else {
            return
        }
        preferences[keyPath: keyPath] = value
        try sharedPreferencesDatasource.upsertPreferences(preferences)
        sharedPreferences.send(preferences)
        sharedPreferencesUpdates.send(.init(keyPath: keyPath, value: value))
    }

    func removeSharedPreferences() async throws {
        try sharedPreferencesDatasource.removePreferences()
    }
}

private extension PreferencesManager {
    func assertDidSetUp() -> Bool {
        assert(didSetUp, "PreferencesManager not set up. Call setUp() function as soon as possible.")
        return didSetUp
    }
}

public extension Publisher {
    /// Filter update events of a given property and return the updated value of the property
    func filter<T, V>(_ keyPath: KeyPath<T, V>) -> AnyPublisher<V, Failure>
        where Output == PreferencesUpdate<T> {
        compactMap { update in
            guard keyPath == update.keyPath as? KeyPath<T, V>,
                  let value = update.value as? V else {
                assertionFailure("keyPath and value type should be matched")
                return nil
            }
            return value
        }
        .eraseToAnyPublisher()
    }
}
