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

// periphery:ignore:all
import Combine
import Core
import Entities
import Foundation

public enum UserPreferencesUpdateEvent {
    case none
    case creation(UserID, UserPreferences)
    case removal(UserID)
    case update(UserID, PartialKeyPath<UserPreferences>, Any)
}

public protocol PreferencesManagerProtocol {
    var userPreferencesUpdates: CurrentValueSubject<UserPreferencesUpdateEvent, Never> { get }

    func create(preferences: UserPreferences, for userId: String) async throws
    func remove(preferences: UserPreferences, for userId: String) async throws
    func updatePreferences<T>(_ keyPath: WritableKeyPath<UserPreferences, T>,
                              value: T,
                              for userId: String) async throws
    func getPreferences(for userId: String) async throws -> UserPreferences?
}

public final class PreferencesManager: PreferencesManagerProtocol {
    public let userPreferencesUpdates = CurrentValueSubject<UserPreferencesUpdateEvent, Never>(.none)

    private let userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol

    public init(symmetricKeyProvider: any SymmetricKeyProvider,
                databaseService: any DatabaseServiceProtocol) {
        userPreferencesDatasource = LocalUserPreferencesDatasource(symmetricKeyProvider: symmetricKeyProvider,
                                                                   databaseService: databaseService)
    }
}

public extension PreferencesManager {
    func create(preferences: UserPreferences, for userId: String) async throws {
        try await userPreferencesDatasource.upsertPreferences(preferences, for: userId)
        userPreferencesUpdates.send(.creation(userId, preferences))
    }

    func remove(preferences: UserPreferences, for userId: String) async throws {
        try await userPreferencesDatasource.removePreferences(for: userId)
        userPreferencesUpdates.send(.removal(userId))
    }

    func updatePreferences<T>(_ keyPath: WritableKeyPath<UserPreferences, T>,
                              value: T,
                              for userId: String) async throws {
        guard var preferences = try await userPreferencesDatasource.getPreferences(for: userId) else {
            throw PassError.userPreferencesNotFound(userId)
        }
        preferences[keyPath: keyPath] = value
        try await userPreferencesDatasource.upsertPreferences(preferences, for: userId)
        userPreferencesUpdates.send(.update(userId, keyPath, value))
    }

    func getPreferences(for userId: String) async throws -> UserPreferences? {
        try await userPreferencesDatasource.getPreferences(for: userId)
    }
}

public extension CurrentValueSubject where Output == UserPreferencesUpdateEvent, Failure == Never {
    /// Filter update events of a given property for a given `userID`
    /// Return the updated value of the property
    func filterUserPreferencesUpdate<T>(_ keyPath: KeyPath<UserPreferences, T>,
                                        userId: String) -> AnyPublisher<T, Failure> {
        compactMap { event in
            guard case let .update(currentUserId, partialKeyPath, anyValue) = event,
                  currentUserId == userId,
                  let currentKeyPath = partialKeyPath as? KeyPath<UserPreferences, T>,
                  keyPath == currentKeyPath,
                  let value = anyValue as? T else {
                return nil
            }
            return value
        }
        .eraseToAnyPublisher()
    }
}
