//
// ShouldShowFolderSyncBannerTests.swift
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
import ClientMocks
import Core
import CoreMocks
import Entities
import Foundation
import ProtonCoreLogin
import Testing
import UseCasesMocks

@Suite(.serialized)
struct ShouldShowFolderSyncBannerTests {
    private let store = PreferencesStore()
    private let hasFolders = HasFoldersStub()
    private let userManager = UserManagerProtocolMock()
    private let storage: UserDefaults
    private let userId: String
    private let flagName = "PassForceSyncFolders"

    init() {
        let userData = UserData.random()
        userId = userData.user.ID
        userManager.stubbedCurrentActiveUser = .init(userData)
        storage = UserDefaults(suiteName: "folderSyncBannerTests")!
        storage.removePersistentDomain(forName: "folderSyncBannerTests")
    }

    private func makeSut(flagOn: Bool = true,
                         recheckDelay: TimeInterval = 30 * 60)
        -> any ShouldShowFolderSyncBannerUseCase {
        ShouldShowFolderSyncBanner(getUserPreferences: GetPreferencesStub(store: store),
                                   getFeatureFlagStatus:
                                   FeatureFlagStub(enabled: flagOn ? [flagName] : []),
                                   userHasRemoteFolders: hasFolders,
                                   userManager: userManager,
                                   storage: storage,
                                   logManager: LogManagerProtocolMock(),
                                   recheckDelay: recheckDelay)
    }

    @Test
    func `No banner once the repair has completed`() async {
        store.setState(done: true)

        let shown = await makeSut().execute()
        #expect(shown == false)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `No banner and no network call when the flag is off`() async {
        let shown = await makeSut(flagOn: false).execute()
        #expect(shown == false)
        #expect(hasFolders.callCount == 0)
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `No banner when there is no active user`() async {
        userManager.stubbedCurrentActiveUser = .init(nil)

        let shown = await makeSut().execute()
        #expect(shown == false)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `Banner shown and the positive cached when folders exist`() async {
        hasFolders.result = true

        let shown = await makeSut().execute()
        #expect(shown == true)
        #expect(storage.bool(forKey: ShouldShowFolderSyncBanner.foldersFoundKey(userId)))
        // The extension must not write the preferences row at all: that write would carry its
        // stale copy of every other field, including resurrecting `done`.
        #expect(store.writtenStates.isEmpty)
        #expect(store.state.attempts == 0)
        #expect(!store.state.done)
    }

    @Test
    func `A positive found by the app is honoured without a lookup`() async {
        store.setState(foldersDetected: true)

        let shown = await makeSut().execute()
        #expect(shown == true)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `A cached positive skips the network`() async {
        storage.set(true, forKey: ShouldShowFolderSyncBanner.foldersFoundKey(userId))

        let shown = await makeSut().execute()
        #expect(shown == true)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `A negative is not cached, so the banner can still appear later`() async {
        hasFolders.result = false

        let shown = await makeSut().execute()
        #expect(shown == false)
        #expect(!storage.bool(forKey: ShouldShowFolderSyncBanner.foldersFoundKey(userId)))
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `Back-to-back presentations do not refire the lookup`() async {
        let sut = makeSut(recheckDelay: 30 * 60)

        for _ in 0..<3 {
            let shown = await sut.execute()
            #expect(shown == false)
        }
        // Without the throttle this would be one fan-out per AutoFill presentation.
        #expect(hasFolders.callCount == 1)
    }

    @Test
    func `The lookup runs again once the recheck window has elapsed`() async {
        storage.set(Date().addingTimeInterval(-31 * 60),
                    forKey: ShouldShowFolderSyncBanner.lastCheckKey(userId))

        let shown = await makeSut(recheckDelay: 30 * 60).execute()
        #expect(shown == false)
        #expect(hasFolders.callCount == 1)
    }

    @Test
    func `A failed lookup is throttled rather than retried immediately`() async {
        hasFolders.error = FolderSyncTestError.boom
        let sut = makeSut(recheckDelay: 30 * 60)

        for _ in 0..<2 {
            let shown = await sut.execute()
            #expect(shown == false)
        }
        #expect(hasFolders.callCount == 1)
    }
}
