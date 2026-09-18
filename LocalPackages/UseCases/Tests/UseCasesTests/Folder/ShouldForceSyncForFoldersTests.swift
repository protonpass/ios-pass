//
// ShouldForceSyncForFoldersTests.swift
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
import Testing

/// Shared preference store so writes made by the use case are visible to subsequent reads,
/// which is what the multi-attempt cases exercise.
private final class PreferencesStore: @unchecked Sendable {
    var preferences = UserPreferences.default
    private(set) var writtenStates: [FolderForceSyncState] = []
    private let lock = NSLock()

    func record(_ state: FolderForceSyncState) {
        lock.withLock {
            preferences.folderForceSync = state
            writtenStates.append(state)
        }
    }
}

private struct GetPreferencesStub: GetUserPreferencesUseCase {
    let store: PreferencesStore
    func execute() -> UserPreferences {
        store.preferences
    }
}

private struct UpdatePreferencesStub: UpdateUserPreferencesUseCase {
    let store: PreferencesStore
    func execute<T: Sendable>(_ keyPath: WritableKeyPath<UserPreferences, T>, value: T) async throws {
        guard let state = value as? FolderForceSyncState else {
            fatalError("Only the folder force sync state is expected here")
        }
        store.record(state)
    }
}

/// Keyed by flag so the two folder flags can be varied independently, which the single stubbed
/// result on the generated mock cannot express.
private struct FeatureFlagStub: GetFeatureFlagStatusUseCase {
    let enabled: Set<String>
    func execute(for flag: any FeatureFlagTypeProtocol) -> Bool {
        enabled.contains(flag.rawValue)
    }
}

private final class HasFoldersStub: UserHasRemoteFoldersUseCase, @unchecked Sendable {
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

private final class ReachabilityStub: ReachabilityServicing {
    let reachabilityInfos = CurrentValueSubject<NWPath?, Never>(nil)
    let isNetworkAvailable: CurrentValueSubject<Bool, Never>
    let typeOfCurrentConnection = CurrentValueSubject<NerworkType, Never>(.unknown)

    init(available: Bool) {
        isNetworkAvailable = .init(available)
    }
}

private enum TestError: Error {
    case boom
}

@Suite(.serialized)
struct ShouldForceSyncForFoldersTests {
    private let store = PreferencesStore()
    private let hasFolders = HasFoldersStub()
    private let userId = "test_user_id"

    private func makeSut(flagOn: Bool = true,
                         online: Bool = true,
                         maxAttempts: Int = 10,
                         retryDelay: TimeInterval = 30 * 60) -> any ShouldForceSyncForFoldersUseCase {
        ShouldForceSyncForFolders(getUserPreferences: GetPreferencesStub(store: store),
                                  getFeatureFlagStatus:
                                  FeatureFlagStub(enabled: flagOn ? ["FolderForceSync"] : []),
                                  userHasRemoteFolders: hasFolders,
                                  updateUserPreferences: UpdatePreferencesStub(store: store),
                                  reachability: ReachabilityStub(available: online),
                                  maxAttempts: maxAttempts,
                                  retryDelay: retryDelay)
    }

    private func setState(done: Bool = false,
                          attempts: Int = 0,
                          lastAttempt: Date? = nil,
                          foldersDetected: Bool = false) {
        store.preferences.folderForceSync = .init(done: done,
                                                  attempts: attempts,
                                                  lastAttempt: lastAttempt,
                                                  foldersDetected: foldersDetected)
    }

    @Test
    func `Already synced users are never checked again`() async throws {
        setState(done: true)

        #expect(try await makeSut()(userId: userId) == false)
        #expect(hasFolders.callCount == 0)
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `Stops permanently once the retry budget is spent`() async throws {
        setState(attempts: 10)

        #expect(try await makeSut(maxAttempts: 10)(userId: userId) == false)
        #expect(hasFolders.callCount == 0)
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `Flag off means no network call and no state written, so the user stays eligible`() async throws {
        #expect(try await makeSut(flagOn: false)(userId: userId) == false)
        #expect(hasFolders.callCount == 0)
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `Being offline does not consume an attempt`() async throws {
        #expect(try await makeSut(online: false)(userId: userId) == false)
        #expect(hasFolders.callCount == 0)
        #expect(store.preferences.folderForceSync.attempts == 0)
    }

    @Test
    func `A recent attempt is not retried before the delay elapses`() async throws {
        setState(attempts: 1, lastAttempt: Date().addingTimeInterval(-5 * 60))

        #expect(try await makeSut(retryDelay: 30 * 60)(userId: userId) == false)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `Retries once the delay has elapsed, consuming exactly one attempt`() async throws {
        setState(attempts: 1, lastAttempt: Date().addingTimeInterval(-31 * 60))
        hasFolders.result = true

        #expect(try await makeSut(retryDelay: 30 * 60)(userId: userId) == true)
        #expect(hasFolders.callCount == 1)
        #expect(store.preferences.folderForceSync.attempts == 2)
    }

    @Test
    func `Folders found: caller is told to sync, and the positive is cached`() async throws {
        hasFolders.result = true

        #expect(try await makeSut()(userId: userId) == true)
        #expect(store.preferences.folderForceSync.foldersDetected)
        // Only a completed full sync may set `done`.
        #expect(!store.preferences.folderForceSync.done)
    }

    @Test
    func `No folders: nothing to repair, so the user is marked done and never cached negative`() async throws {
        hasFolders.result = false

        #expect(try await makeSut()(userId: userId) == false)
        #expect(store.preferences.folderForceSync.done)
        #expect(!store.preferences.folderForceSync.foldersDetected)
    }

    @Test
    func `A cached positive skips the network entirely`() async throws {
        setState(foldersDetected: true)

        #expect(try await makeSut()(userId: userId) == true)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `A thrown lookup still consumes the attempt, so failures cannot loop forever`() async throws {
        hasFolders.error = TestError.boom

        await #expect(throws: TestError.self) {
            try await makeSut()(userId: userId)
        }
        #expect(store.preferences.folderForceSync.attempts == 1)
        #expect(store.preferences.folderForceSync.lastAttempt != nil)
        #expect(!store.preferences.folderForceSync.done)
    }

    @Test
    func `Ten failures exhaust the budget and the eleventh check makes no call`() async throws {
        hasFolders.error = TestError.boom

        for _ in 0..<10 {
            // Zero delay so the throttle does not mask the budget being counted.
            await #expect(throws: TestError.self) {
                try await makeSut(retryDelay: 0)(userId: userId)
            }
        }
        #expect(store.preferences.folderForceSync.attempts == 10)

        let callsBefore = hasFolders.callCount
        #expect(try await makeSut(retryDelay: 0)(userId: userId) == false)
        #expect(hasFolders.callCount == callsBefore)
    }
}
