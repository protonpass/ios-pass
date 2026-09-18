//
// FolderSyncTestDoubles.swift
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

@testable import UseCases
import Client
import Combine
import Core
import Entities
import Foundation
import Network
import ProtonCoreFeatureFlags

enum FolderSyncTestError: Error {
    case boom
}

/// Shared preference store, so writes made by a use case are visible to its subsequent reads.
/// That is what the throttle and budget cases exercise.
final class PreferencesStore: @unchecked Sendable {
    var preferences = UserPreferences.default
    private(set) var writtenStates: [FolderForceSyncState] = []
    private let lock = NSLock()

    var state: FolderForceSyncState {
        lock.withLock { preferences.folderForceSync }
    }

    func setState(done: Bool = false,
                  attempts: Int = 0,
                  lastAttempt: Date? = nil,
                  foldersDetected: Bool = false,
                  lastExtensionCheck: Date? = nil) {
        lock.withLock {
            preferences.folderForceSync = .init(done: done,
                                                attempts: attempts,
                                                lastAttempt: lastAttempt,
                                                foldersDetected: foldersDetected,
                                                lastExtensionCheck: lastExtensionCheck)
        }
    }

    func record(_ state: FolderForceSyncState) {
        lock.withLock {
            preferences.folderForceSync = state
            writtenStates.append(state)
        }
    }
}

struct GetPreferencesStub: GetUserPreferencesUseCase {
    let store: PreferencesStore

    func execute() -> UserPreferences {
        store.preferences
    }
}

struct UpdatePreferencesStub: UpdateUserPreferencesUseCase {
    let store: PreferencesStore

    func execute<T: Sendable>(_ keyPath: WritableKeyPath<UserPreferences, T>, value: T) async throws {
        guard let state = value as? FolderForceSyncState else {
            fatalError("Only the folder force sync state is expected here")
        }
        store.record(state)
    }
}

/// Keyed by flag so flags can be varied independently, which the single stubbed result on the
/// generated mock cannot express.
struct FeatureFlagStub: GetFeatureFlagStatusUseCase {
    let enabled: Set<String>

    func execute(for flag: any FeatureFlagTypeProtocol) -> Bool {
        enabled.contains(flag.rawValue)
    }
}

final class HasFoldersStub: UserHasRemoteFoldersUseCase, @unchecked Sendable {
    var result = false
    var error: (any Error)?
    private(set) var callCount = 0
    private let lock = NSLock()

    @concurrent
    func execute(userId: String) async throws -> Bool {
        lock.withLock { callCount += 1 }
        if let error {
            throw error
        }
        return result
    }
}

final class ReachabilityStub: ReachabilityServicing {
    let reachabilityInfos = CurrentValueSubject<NWPath?, Never>(nil)
    let isNetworkAvailable: CurrentValueSubject<Bool, Never>
    let typeOfCurrentConnection = CurrentValueSubject<NerworkType, Never>(.unknown)

    init(available: Bool) {
        isNetworkAvailable = .init(available)
    }
}
