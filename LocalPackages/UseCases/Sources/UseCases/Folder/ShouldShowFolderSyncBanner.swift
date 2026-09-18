//
// ShouldShowFolderSyncBanner.swift
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

/// Whether an extension should tell the user to open the main app to repair folder data.
///
/// Extensions never run a full sync, so the repair can only happen in the app. This asks the same
/// questions as `ShouldForceSyncForFoldersUseCase` — not already synced, flag on, and folders
/// actually exist — but keeps its own rate limit and records no attempt, because showing a banner
/// is not a repair attempt and consuming that budget would starve the app's real ones.
public protocol ShouldShowFolderSyncBannerUseCase: Sendable {
    @concurrent
    func execute() async -> Bool
}

public extension ShouldShowFolderSyncBannerUseCase {
    @concurrent
    func callAsFunction() async -> Bool {
        await execute()
    }
}

public struct ShouldShowFolderSyncBanner: ShouldShowFolderSyncBannerUseCase {
    private let getUserPreferences: any GetUserPreferencesUseCase
    private let getFeatureFlagStatus: any GetFeatureFlagStatusUseCase
    private let userHasRemoteFolders: any UserHasRemoteFoldersUseCase
    private let updateUserPreferences: any UpdateUserPreferencesUseCase
    private let userManager: any UserManagerProtocol
    private let logger: Logger
    private let recheckDelay: TimeInterval

    public init(getUserPreferences: any GetUserPreferencesUseCase,
                getFeatureFlagStatus: any GetFeatureFlagStatusUseCase,
                userHasRemoteFolders: any UserHasRemoteFoldersUseCase,
                updateUserPreferences: any UpdateUserPreferencesUseCase,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol,
                recheckDelay: TimeInterval = 30 * 60) {
        self.getUserPreferences = getUserPreferences
        self.getFeatureFlagStatus = getFeatureFlagStatus
        self.userHasRemoteFolders = userHasRemoteFolders
        self.updateUserPreferences = updateUserPreferences
        self.userManager = userManager
        self.recheckDelay = recheckDelay
        logger = .init(manager: logManager)
    }

    @concurrent
    public func execute() async -> Bool {
        guard let userId = userManager.activeUserId else { return false }

        var state = getUserPreferences().folderForceSync
        guard !state.done,
              getFeatureFlagStatus(for: FeatureFlagType.folderForceSync) else { return false }

        if state.foldersDetected {
            return true
        }

        if let lastCheck = state.lastExtensionCheck,
           Date().timeIntervalSince(lastCheck) < recheckDelay {
            return false
        }

        do {
            state.lastExtensionCheck = Date()
            try await updateUserPreferences(\.folderForceSync, value: state)

            let hasFolders = try await userHasRemoteFolders(userId: userId)
            guard hasFolders else { return false }
            state.foldersDetected = true
            try await updateUserPreferences(\.folderForceSync, value: state)
            return true
        } catch {
            logger.error(error)
            return false
        }
    }
}
