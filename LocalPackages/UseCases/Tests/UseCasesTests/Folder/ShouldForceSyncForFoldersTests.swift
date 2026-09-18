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
                                  FeatureFlagStub(enabled: flagOn ? ["PassForceSyncFolders"] : []),
                                  userHasRemoteFolders: hasFolders,
                                  updateUserPreferences: UpdatePreferencesStub(store: store),
                                  reachability: ReachabilityStub(available: online),
                                  maxAttempts: maxAttempts,
                                  retryDelay: retryDelay)
    }

    @Test
    func `Already synced users are never checked again`() async throws {
        store.setState(done: true)

        #expect(try await makeSut()(userId: userId) == false)
        #expect(hasFolders.callCount == 0)
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `Stops permanently once the retry budget is spent`() async throws {
        store.setState(attempts: 10)

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
        #expect(store.state.attempts == 0)
    }

    @Test
    func `A recent attempt is not retried before the delay elapses`() async throws {
        store.setState(attempts: 1, lastAttempt: Date().addingTimeInterval(-5 * 60))

        #expect(try await makeSut(retryDelay: 30 * 60)(userId: userId) == false)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `Retries once the delay has elapsed, consuming exactly one attempt`() async throws {
        store.setState(attempts: 1, lastAttempt: Date().addingTimeInterval(-31 * 60))
        hasFolders.result = true

        #expect(try await makeSut(retryDelay: 30 * 60)(userId: userId) == true)
        #expect(hasFolders.callCount == 1)
        #expect(store.state.attempts == 2)
    }

    @Test
    func `Folders found: caller is told to sync, and the positive is cached`() async throws {
        hasFolders.result = true

        #expect(try await makeSut()(userId: userId) == true)
        #expect(store.state.foldersDetected)
        // Only a completed full sync may set `done`.
        #expect(!store.state.done)
    }

    @Test
    func `No folders: nothing to repair, so the user is marked done and never cached negative`() async throws {
        hasFolders.result = false

        #expect(try await makeSut()(userId: userId) == false)
        #expect(store.state.done)
        #expect(!store.state.foldersDetected)
    }

    @Test
    func `A cached positive skips the network but still consumes an attempt`() async throws {
        store.setState(foldersDetected: true)

        #expect(try await makeSut()(userId: userId) == true)
        #expect(hasFolders.callCount == 0)
        // The caller's full sync wipes before re-downloading and only marks `done` on success,
        // so this path must be budgeted too or a failing sync re-wipes on every event loop.
        #expect(store.state.attempts == 1)
        #expect(store.state.lastAttempt != nil)
    }

    @Test
    func `A cached positive is throttled between attempts`() async throws {
        store.setState(attempts: 1,
                       lastAttempt: Date().addingTimeInterval(-5 * 60),
                       foldersDetected: true)

        #expect(try await makeSut(retryDelay: 30 * 60)(userId: userId) == false)
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `A cached positive stops once the budget is spent`() async throws {
        store.setState(attempts: 10, foldersDetected: true)

        #expect(try await makeSut(maxAttempts: 10)(userId: userId) == false)
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `A repeatedly failing sync exhausts the budget instead of looping`() async throws {
        store.setState(foldersDetected: true)
        let sut = makeSut(maxAttempts: 3, retryDelay: 0)

        // Mimics the caller force syncing and failing: `done` is never set.
        for _ in 0..<3 {
            #expect(try await sut(userId: userId) == true)
        }
        #expect(store.state.attempts == 3)
        #expect(try await sut(userId: userId) == false)
    }

    @Test
    func `A thrown lookup still consumes the attempt, so failures cannot loop forever`() async throws {
        hasFolders.error = FolderSyncTestError.boom

        await #expect(throws: FolderSyncTestError.self) {
            try await makeSut()(userId: userId)
        }
        #expect(store.state.attempts == 1)
        #expect(store.state.lastAttempt != nil)
        #expect(!store.state.done)
    }

    @Test
    func `Ten failures exhaust the budget and the eleventh check makes no call`() async throws {
        hasFolders.error = FolderSyncTestError.boom

        for _ in 0..<10 {
            // Zero delay so the throttle does not mask the budget being counted.
            await #expect(throws: FolderSyncTestError.self) {
                try await makeSut(retryDelay: 0)(userId: userId)
            }
        }
        #expect(store.state.attempts == 10)

        let callsBefore = hasFolders.callCount
        #expect(try await makeSut(retryDelay: 0)(userId: userId) == false)
        #expect(hasFolders.callCount == callsBefore)
    }
}
