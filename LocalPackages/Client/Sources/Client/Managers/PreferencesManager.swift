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

public typealias AppPreferencesUpdate = PreferencesUpdate<AppPreferences>
public typealias SharedPreferencesUpdate = PreferencesUpdate<SharedPreferences>
public typealias UserPreferencesUpdate = PreferencesUpdate<UserPreferences>

// sourcery: AutoMockable
public protocol ThemeProvider: Sendable {
    var sharedPreferences: CurrentValueSubject<SharedPreferences?, Never> { get }
}

/// Manage all types of preferences: app-wide, shared between users and user's specific
public protocol PreferencesManagerProtocol: Sendable, TelemetryThresholdProviderProtocol, ThemeProvider {
    /// Load preferences or create with default values if not exist
    func setUp() async throws

    /// Remove user preferences and some shared preferences like PIN code & biometric
    /// (e.g user is logged out because of failed local authentication)
    func reset() async throws

    /// Remove preferences for all accounts and some shared preferences like PIN code & biometric
    func resetAll() async throws

    // App preferences
    var appPreferences: CurrentValueSubject<AppPreferences?, Never> { get }
    var appPreferencesUpdates: PassthroughSubject<AppPreferencesUpdate, Never> { get }

    func updateAppPreferences<T>(_ keyPath: WritableKeyPath<AppPreferences, T>,
                                 value: T) async throws where T: Sendable
    func removeAppPreferences() async

    // Shared preferences
    var sharedPreferences: CurrentValueSubject<SharedPreferences?, Never> { get }
    var sharedPreferencesUpdates: PassthroughSubject<SharedPreferencesUpdate, Never> { get }

    func updateSharedPreferences<T>(_ keyPath: WritableKeyPath<SharedPreferences, T>,
                                    value: T) async throws where T: Sendable
    func removeSharedPreferences() async throws

    // User's preferences
    var userPreferences: CurrentValueSubject<UserPreferences?, Never> { get }
    var userPreferencesUpdates: PassthroughSubject<UserPreferencesUpdate, Never> { get }

    func switchUserPreferences(userId: String) async throws

    func updateUserPreferences<T>(_ keyPath: WritableKeyPath<UserPreferences, T>,
                                  value: T) async throws where T: Sendable
    func removeUserPreferences() async throws
}

public extension PreferencesManagerProtocol {
    func getThreshold() -> TimeInterval? {
        appPreferences.unwrapped().telemetryThreshold
    }

    func setThreshold(_ threshold: TimeInterval?) async throws {
        try await updateAppPreferences(\.telemetryThreshold, value: threshold)
    }
}

public actor PreferencesManager: PreferencesManagerProtocol {
    public nonisolated let appPreferences = CurrentValueSubject<AppPreferences?, Never>(nil)
    public nonisolated let appPreferencesUpdates = PassthroughSubject<AppPreferencesUpdate, Never>()

    public nonisolated let sharedPreferences = CurrentValueSubject<SharedPreferences?, Never>(nil)
    public nonisolated let sharedPreferencesUpdates = PassthroughSubject<SharedPreferencesUpdate, Never>()

    public nonisolated let userPreferences = CurrentValueSubject<UserPreferences?, Never>(nil)
    public nonisolated let userPreferencesUpdates = PassthroughSubject<UserPreferencesUpdate, Never>()

    private let userManager: any UserManagerProtocol
    private let appPreferencesDatasource: any LocalAppPreferencesDatasourceProtocol
    private let sharedPreferencesDatasource: any LocalSharedPreferencesDatasourceProtocol
    private let userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol
    private let logger: Logger

    private var didSetUp = false

    private let preferencesMigrator: any PreferencesMigrator

    public init(userManager: any UserManagerProtocol,
                appPreferencesDatasource: any LocalAppPreferencesDatasourceProtocol,
                sharedPreferencesDatasource: any LocalSharedPreferencesDatasourceProtocol,
                userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol,
                logManager: any LogManagerProtocol,
                preferencesMigrator: any PreferencesMigrator) {
        self.userManager = userManager
        self.appPreferencesDatasource = appPreferencesDatasource
        self.userPreferencesDatasource = userPreferencesDatasource
        self.sharedPreferencesDatasource = sharedPreferencesDatasource
        logger = .init(manager: logManager)
        self.preferencesMigrator = preferencesMigrator
    }
}

public extension PreferencesManager {
    func setUp() async throws {
        logger.trace("Setting up preferences manager")

        // App preferences
        if let preferences = try appPreferencesDatasource.getPreferences() {
            appPreferences.send(preferences)
        } else {
            let preferences = AppPreferences.default
            try appPreferencesDatasource.upsertPreferences(preferences)
            appPreferences.send(preferences)
            // When entering this code path, the app might be reinstalled
            // so we remove shared preferences which survives because it's stored in Keychain
            try sharedPreferencesDatasource.removePreferences()
        }

        // Shared preferences
        if let preferences = try await sharedPreferencesDatasource.getPreferences() {
            sharedPreferences.send(preferences)
        } else {
            let preferences = SharedPreferences.default
            try await sharedPreferencesDatasource.upsertPreferences(preferences)
            sharedPreferences.send(preferences)
        }

        // User's preferences
        if let userId = try? await userManager.getActiveUserId() {
            try await setUserPreferences(userId: userId)
        }

        // Migrations
        if !appPreferences.unwrapped().didMigratePreferences {
            logger.trace("Migrating preferences")
            let (app, shared, user) = preferencesMigrator.migratePreferences()

            try appPreferencesDatasource.upsertPreferences(app)
            appPreferences.send(app)

            try await sharedPreferencesDatasource.upsertPreferences(shared)
            sharedPreferences.send(shared)

            if let userId = try? await userManager.getActiveUserId() {
                try await userPreferencesDatasource.upsertPreferences(user, for: userId)
                userPreferences.send(user)
            }

            logger.trace("Migrated preferences")
        }

        logger.info("Set up preferences manager")
        didSetUp = true
    }

    func reset() async throws {
        assertDidSetUp()
        try await resetSharedPreferences()
        try await removeUserPreferences()
    }

    func resetAll() async throws {
        assertDidSetUp()
        try await resetSharedPreferences()
        try await removeAllPreferences()
    }
}

private extension PreferencesManager {
    func resetSharedPreferences() async throws {
        try await updateSharedPreferences(\.localAuthenticationMethod, value: .none)
        try await updateSharedPreferences(\.appLockTime, value: .default)
        try await updateSharedPreferences(\.pinCode, value: nil)
        try await updateSharedPreferences(\.failedAttemptCount, value: 0)
    }

    func assertDidSetUp() {
        assert(didSetUp, "PreferencesManager not set up. Call setUp() function as soon as possible.")
        if !didSetUp {
            logger.error("PreferencesManager not set up")
        }
    }
}

// MARK: - App preferences

public extension PreferencesManager {
    func updateAppPreferences<T: Sendable>(_ keyPath: WritableKeyPath<AppPreferences, T>,
                                           value: T) async throws {
        logger.trace("Updating app preferences \(keyPath)")
        assertDidSetUp()
        guard var preferences = appPreferences.value else {
            throw PassError.preferences(.appPreferencesNotInitialized)
        }
        preferences[keyPath: keyPath] = value
        try appPreferencesDatasource.upsertPreferences(preferences)
        appPreferences.send(preferences)
        appPreferencesUpdates.send(.init(keyPath: keyPath, value: value))
        logger.info("Updated app preferences \(keyPath)")
    }

    func removeAppPreferences() async {
        logger.trace("Removing app preferences")
        appPreferencesDatasource.removePreferences()
        logger.info("Removed app preferences")
    }
}

// MARK: - Shared preferences

public extension PreferencesManager {
    func updateSharedPreferences<T: Sendable>(_ keyPath: WritableKeyPath<SharedPreferences, T>,
                                              value: T) async throws {
        logger.trace("Updating shared preferences \(keyPath)")
        assertDidSetUp()
        guard var preferences = sharedPreferences.value else {
            throw PassError.preferences(.sharedPreferencesNotInitialized)
        }
        preferences[keyPath: keyPath] = value
        try await sharedPreferencesDatasource.upsertPreferences(preferences)
        sharedPreferences.send(preferences)
        sharedPreferencesUpdates.send(.init(keyPath: keyPath, value: value))
        logger.info("Updated shared preferences \(keyPath)")
    }

    func removeSharedPreferences() async throws {
        logger.trace("Removing shared preferences")
        try sharedPreferencesDatasource.removePreferences()
        logger.info("Removed app preferences")
    }
}

// MARK: - User's preferences

public extension PreferencesManager {
    func updateUserPreferences<T: Sendable>(_ keyPath: WritableKeyPath<UserPreferences, T>,
                                            value: T) async throws {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Updating user preferences \(keyPath) for user \(userId)")
        assertDidSetUp()
        guard var preferences = userPreferences.value else {
            throw PassError.preferences(.userPreferencesNotInitialized)
        }
        preferences[keyPath: keyPath] = value
        try await userPreferencesDatasource.upsertPreferences(preferences, for: userId)
        userPreferences.send(preferences)
        userPreferencesUpdates.send(.init(keyPath: keyPath, value: value))
        logger.info("Updated user preferences \(keyPath) for user \(userId)")
    }

    func removeUserPreferences() async throws {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Removing user preferences for user \(userId)")
        try await userPreferencesDatasource.removePreferences(for: userId)
        userPreferences.send(nil)
        logger.info("Removed user preferences for user \(userId)")
    }

    func removeAllPreferences() async throws {
        logger.trace("Removing all preferences")
        try await userPreferencesDatasource.removeAllPreferences()
        userPreferences.send(nil)
        logger.info("Removed all preferences")
    }

    func switchUserPreferences(userId: String) async throws {
        try await setUserPreferences(userId: userId)
    }
}

public extension Publisher {
    /// Filter update events of a given property and return the updated value of the property
    func filter<T, V>(_ keyPath: KeyPath<T, V>) -> AnyPublisher<V, Failure>
        where Output == PreferencesUpdate<T> {
        compactMap { update -> V? in
            guard keyPath == update.keyPath as? KeyPath<T, V> else {
                return nil
            }

            if let optional = update.value as? (any AnyOptional), optional.isNil {
                return optional as? V
            }

            return update.value as? V
        }
        .eraseToAnyPublisher()
    }

    /// Filter by multiple keypaths and return `Void` to indicate positive result
    func filter<T>(_ keyPaths: [PartialKeyPath<T>]) -> AnyPublisher<Void, Failure>
        where Output == PreferencesUpdate<T> {
        filter { update in
            keyPaths.contains { type(of: update.keyPath) == type(of: $0) }
        }
        .map { _ in () }
        .eraseToAnyPublisher()
    }
}

// MARK: - Utils

private extension PreferencesManager {
    func setUserPreferences(userId: String) async throws {
        if let preferences = try await userPreferencesDatasource.getPreferences(for: userId) {
            userPreferences.send(preferences)
        } else {
            let preferences = UserPreferences.default
            try await userPreferencesDatasource.upsertPreferences(preferences, for: userId)
            userPreferences.send(preferences)
        }
    }
}
