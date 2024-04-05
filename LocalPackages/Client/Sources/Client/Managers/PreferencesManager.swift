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
import Entities
import Foundation

/// Should not deal with this object directly from the outside
/// but use `filter` operator to parse and filter updates
public struct PreferencesUpdate<T>: @unchecked Sendable {
    public let keyPath: PartialKeyPath<T>
    public let value: any Sendable
}

public typealias AppPreferencesUpdate = PreferencesUpdate<AppPreferences>
public typealias SharedPreferencesUpdate = PreferencesUpdate<SharedPreferences>
public typealias UserPreferencesUpdate = PreferencesUpdate<UserPreferences>

/// Manage all types of preferences: app-wide, shared between users and user's specific
public protocol PreferencesManagerProtocol {
    /// Load preferences or create with default values if not exist
    func setUp() async throws

    // App preferences
    var appPreferences: CurrentValueSubject<AppPreferences?, Never> { get }
    var appPreferencesUpdates: PassthroughSubject<AppPreferencesUpdate, Never> { get }

    func updateAppPreferences<T: Sendable>(_ keyPath: WritableKeyPath<AppPreferences, T>,
                                           value: T) async throws
    func removeAppPreferences() async

    // Shared preferences
    var sharedPreferences: CurrentValueSubject<SharedPreferences?, Never> { get }
    var sharedPreferencesUpdates: PassthroughSubject<SharedPreferencesUpdate, Never> { get }

    func updateSharedPreferences<T: Sendable>(_ keyPath: WritableKeyPath<SharedPreferences, T>,
                                              value: T) async throws
    func removeSharedPreferences() async throws

    // User's preferences
    var userPreferences: CurrentValueSubject<UserPreferences?, Never> { get }
    var userPreferencesUpdates: PassthroughSubject<UserPreferencesUpdate, Never> { get }

    func updateUserPreferences<T: Sendable>(_ keyPath: WritableKeyPath<UserPreferences, T>,
                                            value: T) async throws
    func removeUserPreferences() async throws
}

public actor PreferencesManager: PreferencesManagerProtocol {
    public nonisolated let appPreferences = CurrentValueSubject<AppPreferences?, Never>(nil)
    public nonisolated let appPreferencesUpdates = PassthroughSubject<AppPreferencesUpdate, Never>()

    public nonisolated let sharedPreferences = CurrentValueSubject<SharedPreferences?, Never>(nil)
    public nonisolated let sharedPreferencesUpdates = PassthroughSubject<SharedPreferencesUpdate, Never>()

    public nonisolated let userPreferences = CurrentValueSubject<UserPreferences?, Never>(nil)
    public nonisolated let userPreferencesUpdates = PassthroughSubject<UserPreferencesUpdate, Never>()

    private let appPreferencesDatasource: any LocalAppPreferencesDatasourceProtocol
    private let sharedPreferencesDatasource: any LocalSharedPreferencesDatasourceProtocol
    private let userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol
    // swiftlint:disable:next todo
    // TODO: Inject via a protocol
    private let userId: String

    private var didSetUp = false

    public init(appPreferencesDatasource: any LocalAppPreferencesDatasourceProtocol,
                sharedPreferencesDatasource: any LocalSharedPreferencesDatasourceProtocol,
                userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol,
                userId: String = "") {
        self.appPreferencesDatasource = appPreferencesDatasource
        self.userPreferencesDatasource = userPreferencesDatasource
        self.sharedPreferencesDatasource = sharedPreferencesDatasource
        self.userId = userId
    }
}

public extension PreferencesManager {
    func setUp() async throws {
        // App preferences
        if let preferences = try appPreferencesDatasource.getPreferences() {
            appPreferences.send(preferences)
        } else {
            let preferences = AppPreferences.default
            try appPreferencesDatasource.upsertPreferences(preferences)
            appPreferences.send(preferences)
        }

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

    func assertDidSetUp() {
        assert(didSetUp, "PreferencesManager not set up. Call setUp() function as soon as possible.")
    }
}

// MARK: - App preferences

public extension PreferencesManager {
    func updateAppPreferences<T: Sendable>(_ keyPath: WritableKeyPath<AppPreferences, T>,
                                           value: T) async throws {
        assertDidSetUp()
        guard var preferences = appPreferences.value else {
            throw PassError.preferences(.appPreferencesNotInitialized)
        }
        preferences[keyPath: keyPath] = value
        try appPreferencesDatasource.upsertPreferences(preferences)
        appPreferences.send(preferences)
        appPreferencesUpdates.send(.init(keyPath: keyPath, value: value))
    }

    func removeAppPreferences() async {
        appPreferencesDatasource.removePreferences()
    }
}

// MARK: - Shared preferences

public extension PreferencesManager {
    func updateSharedPreferences<T: Sendable>(_ keyPath: WritableKeyPath<SharedPreferences, T>,
                                              value: T) async throws {
        assertDidSetUp()
        guard var preferences = sharedPreferences.value else {
            throw PassError.preferences(.sharedPreferencesNotInitialized)
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

// MARK: - User's preferences

public extension PreferencesManager {
    func updateUserPreferences<T: Sendable>(_ keyPath: WritableKeyPath<UserPreferences, T>,
                                            value: T) async throws {
        assertDidSetUp()
        guard var preferences = userPreferences.value else {
            throw PassError.preferences(.userPreferencesNotInitialized)
        }
        preferences[keyPath: keyPath] = value
        try await userPreferencesDatasource.upsertPreferences(preferences, for: userId)
        userPreferences.send(preferences)
        userPreferencesUpdates.send(.init(keyPath: keyPath, value: value))
    }

    func removeUserPreferences() async throws {
        try await userPreferencesDatasource.removePreferences(for: userId)
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
