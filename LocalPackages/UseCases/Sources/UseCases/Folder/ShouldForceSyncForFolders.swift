//
// ShouldForceSyncForFolders.swift
// Proton Pass - Created on 18/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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

/// Whether the caller should run a full sync to repair data missed before folder support.
///
/// Returns `true` at most once per user: a successful full sync marks the user done, and this
/// returning `false` for a user with no folders marks them done too.
public protocol ShouldForceSyncForFoldersUseCase: Sendable {
    @concurrent
    func execute(userId: String) async throws -> Bool
}

public extension ShouldForceSyncForFoldersUseCase {
    @concurrent
    func callAsFunction(userId: String) async throws -> Bool {
        try await execute(userId: userId)
    }
}

public struct ShouldForceSyncForFolders: ShouldForceSyncForFoldersUseCase {
    private let getUserPreferences: any GetUserPreferencesUseCase
    private let getFeatureFlagStatus: any GetFeatureFlagStatusUseCase
    private let userHasRemoteFolders: any UserHasRemoteFoldersUseCase
    private let updateUserPreferences: any UpdateUserPreferencesUseCase
    private let reachability: any ReachabilityServicing
    private let maxAttempts: Int
    private let retryDelay: TimeInterval

    public init(getUserPreferences: any GetUserPreferencesUseCase,
                getFeatureFlagStatus: any GetFeatureFlagStatusUseCase,
                userHasRemoteFolders: any UserHasRemoteFoldersUseCase,
                updateUserPreferences: any UpdateUserPreferencesUseCase,
                reachability: any ReachabilityServicing,
                maxAttempts: Int = 10,
                retryDelay: TimeInterval = 30 * 60) {
        self.getUserPreferences = getUserPreferences
        self.getFeatureFlagStatus = getFeatureFlagStatus
        self.userHasRemoteFolders = userHasRemoteFolders
        self.updateUserPreferences = updateUserPreferences
        self.reachability = reachability
        self.maxAttempts = maxAttempts
        self.retryDelay = retryDelay
    }

    @concurrent
    public func execute(userId: String) async throws -> Bool {
        var state = getUserPreferences().folderForceSync
        guard !state.done, state.attempts < maxAttempts else { return false }
        guard getFeatureFlagStatus(for: FeatureFlagType.folderForceSync) else { return false }
        guard reachability.isNetworkAvailable.value else { return false }

        if let lastAttempt = state.lastAttempt,
           Date().timeIntervalSince(lastAttempt) < retryDelay {
            return false
        }

        state.attempts += 1
        state.lastAttempt = Date()
        try await updateUserPreferences(\.folderForceSync, value: state)

        if state.foldersDetected {
            return true
        }

        let hasFolders = try await userHasRemoteFolders(userId: userId)
        if hasFolders {
            state.foldersDetected = true
        } else {
            state.done = true
        }
        try await updateUserPreferences(\.folderForceSync, value: state)
        return hasFolders
    }
}
