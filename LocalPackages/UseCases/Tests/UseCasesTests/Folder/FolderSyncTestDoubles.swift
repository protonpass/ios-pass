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
    private var _preferences = UserPreferences.default
    private var _writtenStates: [FolderForceSyncState] = []
    private let lock = NSLock()

    var preferences: UserPreferences {
        lock.withLock { _preferences }
    }

    var writtenStates: [FolderForceSyncState] {
        lock.withLock { _writtenStates }
    }

    var state: FolderForceSyncState {
        lock.withLock { _preferences.folderForceSync }
    }

    func setState(done: Bool = false,
                  attempts: Int = 0,
                  lastAttempt: Date? = nil,
                  foldersDetected: Bool = false) {
        lock.withLock {
            _preferences.folderForceSync = .init(done: done,
                                                 attempts: attempts,
                                                 lastAttempt: lastAttempt,
                                                 foldersDetected: foldersDetected)
        }
    }

    func record(_ state: FolderForceSyncState) {
        lock.withLock {
            _preferences.folderForceSync = state
            _writtenStates.append(state)
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
final class FeatureFlagStub: GetFeatureFlagStatusUseCase, @unchecked Sendable {
    private var _enabled: Set<String>
    private let lock = NSLock()

    init(enabled: Set<String>) {
        _enabled = enabled
    }

    var enabled: Set<String> {
        get { lock.withLock { _enabled } }
        set { lock.withLock { _enabled = newValue } }
    }

    func execute(for flag: any FeatureFlagTypeProtocol) -> Bool {
        lock.withLock { _enabled.contains(flag.rawValue) }
    }
}

final class HasFoldersStub: UserHasRemoteFoldersUseCase, @unchecked Sendable {
    var result = false
    var error: (any Error)?
    private var _callCount = 0
    private let lock = NSLock()

    var callCount: Int {
        lock.withLock { _callCount }
    }

    func execute(userId: String) async throws -> Bool {
        lock.withLock { _callCount += 1 }
        if let error {
            throw error
        }
        return result
    }
}

final class RefreshFeatureFlagsStub: RefreshFeatureFlagsUseCase, @unchecked Sendable {
    /// Applied when the refresh runs, so a test can model the kill switch flipping server side
    /// between the cached read and the live one.
    var onRefresh: (@Sendable () -> Void)?
    private var _callCount = 0
    private let lock = NSLock()

    var callCount: Int {
        lock.withLock { _callCount }
    }

    func execute() {
        Task { await execute() }
    }

    func execute() async {
        lock.withLock { _callCount += 1 }
        onRefresh?()
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
