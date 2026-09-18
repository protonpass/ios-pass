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
import Testing
import UseCasesMocks

@Suite(.serialized)
struct ShouldShowFolderSyncBannerTests {
    private let store = PreferencesStore()
    private let hasFolders = HasFoldersStub()
    private let userManager = UserManagerProtocolMock()
    private let flagName = "PassForceSyncFolders"

    init() {
        userManager.stubbedCurrentActiveUser = .init(.random())
    }

    private func makeSut(flagOn: Bool = true,
                         recheckDelay: TimeInterval = 30 * 60)
        -> any ShouldShowFolderSyncBannerUseCase {
        ShouldShowFolderSyncBanner(getUserPreferences: GetPreferencesStub(store: store),
                                   getFeatureFlagStatus:
                                   FeatureFlagStub(enabled: flagOn ? [flagName] : []),
                                   userHasRemoteFolders: hasFolders,
                                   updateUserPreferences: UpdatePreferencesStub(store: store),
                                   userManager: userManager,
                                   logManager: LogManagerProtocolMock(),
                                   recheckDelay: recheckDelay)
    }

    @Test
    func `No banner once the repair has completed`() async {
        store.setState(done: true)

        #expect(await makeSut()() == false)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `No banner and no network call when the flag is off`() async {
        #expect(await makeSut(flagOn: false)() == false)
        #expect(hasFolders.callCount == 0)
        #expect(store.writtenStates.isEmpty)
    }

    @Test
    func `No banner when there is no active user`() async {
        userManager.stubbedCurrentActiveUser = .init(nil)

        #expect(await makeSut()() == false)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `Banner shown and the positive cached when folders exist`() async {
        hasFolders.result = true

        #expect(await makeSut()() == true)
        #expect(store.state.foldersDetected)
        // The extension must never touch the app's repair budget.
        #expect(store.state.attempts == 0)
        #expect(!store.state.done)
    }

    @Test
    func `A cached positive skips the network`() async {
        store.setState(foldersDetected: true)

        #expect(await makeSut()() == true)
        #expect(hasFolders.callCount == 0)
    }

    @Test
    func `A negative is not cached, so the banner can still appear later`() async {
        hasFolders.result = false

        #expect(await makeSut()() == false)
        #expect(!store.state.foldersDetected)
        #expect(!store.state.done)
    }

    @Test
    func `Back-to-back presentations do not refire the lookup`() async {
        let sut = makeSut(recheckDelay: 30 * 60)

        #expect(await sut() == false)
        #expect(await sut() == false)
        #expect(await sut() == false)
        // Without the throttle this would be one fan-out per AutoFill presentation.
        #expect(hasFolders.callCount == 1)
    }

    @Test
    func `The lookup runs again once the recheck window has elapsed`() async {
        store.setState(lastExtensionCheck: Date().addingTimeInterval(-31 * 60))

        #expect(await makeSut(recheckDelay: 30 * 60)() == false)
        #expect(hasFolders.callCount == 1)
    }

    @Test
    func `A failed lookup is throttled rather than retried immediately`() async {
        hasFolders.error = FolderSyncTestError.boom
        let sut = makeSut(recheckDelay: 30 * 60)

        #expect(await sut() == false)
        #expect(await sut() == false)
        #expect(hasFolders.callCount == 1)
    }
}
