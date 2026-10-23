//
// FullSyncOperationTests.swift
// Proton Pass - Created on 13/10/2026.
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

@testable import Client
import Entities
import Testing

@MainActor
@Suite(.tags(.models))
struct FullSyncOperationTests {
    @Test func `progress events update their own vault until the sync finishes`() {
        let vault = Share.random()
        let emptyVault = Share.random()
        let sut = FullSyncOperation(userId: "user", presentation: .sheet)

        sut.apply(.downloadedShares([vault, emptyVault]))
        sut.apply(.decryptedVault(vault))
        sut.apply(.decryptItems(.init(shareId: vault.shareId, total: 2, decrypted: 1)))
        sut.apply(.getRemoteItems(.init(shareId: emptyVault.shareId, total: 0, downloaded: 0)))
        sut.finish(.cancelled)
        sut.apply(.decryptItems(.init(shareId: vault.shareId, total: 2, decrypted: 2)))

        #expect(sut.progresses.map(\.shareId) == [vault.shareId, emptyVault.shareId])
        #expect(sut.progresses.map(\.vault?.shareId) == [vault.shareId, nil])
        #expect(sut.progresses.map(\.isDone) == [false, true])
    }
}
