//
// InviteRepositoryTests.swift
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
//

@testable import Client
import ClientMocks
import CoreMocks
import Entities
import Testing

@Suite(.tags(.repository))
struct InviteRepositoryTests {
    let remoteDatasource: RemoteInviteDatasourceProtocolMock
    let localDatasource: LocalInviteDatasourceProtocolMock

    let sut: any InviteRepositoryProtocol

    init() {
        remoteDatasource = .init()
        remoteDatasource.stubbedGetPendingGroupInvitesForUserResult = .init(invites: [], total: 0, lastID: nil)
        localDatasource = LocalInviteDatasourceProtocolMock()
        localDatasource.stubbedGetUserInvitesResult = []
        localDatasource.stubbedGetGroupInvitesResult = []
        sut = InviteRepository(remoteDatasource: remoteDatasource,
                               localDatasource: localDatasource,
                               logManager: LogManagerProtocolMock())
    }

    @Test
    func `Refreshing one account does not overwrite another account's pending invites`() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()
        let invite1 = UserInvite.random()
        let invite2 = UserInvite.random()

        // When
        
        remoteDatasource.stubbedGetPendingInvitesForUserResult = [invite1]
        try await sut.refreshAllInvites(userId: userId1)

        remoteDatasource.stubbedGetPendingInvitesForUserResult = [invite2]
        try await sut.refreshAllInvites(userId: userId2)

        // Then
        #expect(sut.currentPendingInvites.value[userId1] == [.user(invite1)])
        #expect(sut.currentPendingInvites.value[userId2] == [.user(invite2)])
    }

    @Test
    func `Loading local invites of one account does not overwrite another account's`() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()
        let invite1 = UserInvite.random()
        let invite2 = UserInvite.random()
        let localInvite = UserInvite.random()

        remoteDatasource.stubbedGetPendingInvitesForUserResult = [invite1]
        try await sut.refreshAllInvites(userId: userId1)
        remoteDatasource.stubbedGetPendingInvitesForUserResult = [invite2]
        try await sut.refreshAllInvites(userId: userId2)

        // Local returns something different from the cached invite2 so a no-op
        // loadLocalInvites cannot pass the userId2 assertion below
        localDatasource.stubbedGetUserInvitesResult = [localInvite]

        // When
        try await sut.loadLocalInvites(userId: userId2)

        // Then
        #expect(localDatasource.invokedGetUserInvitesParameters?.userId == userId2)
        #expect(sut.currentPendingInvites.value[userId1] == [.user(invite1)])
        #expect(sut.currentPendingInvites.value[userId2] == [.user(localInvite)])
    }

    @Test
    func `Removing a cached invite only affects the given account`() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()
        let sharedToken = String.random()
        let invite1 = UserInvite.random(inviteToken: sharedToken)
        let invite2 = UserInvite.random(inviteToken: sharedToken)

        localDatasource.stubbedGetUserInvitesResult = []

        remoteDatasource.stubbedGetPendingInvitesForUserResult = [invite1]
        try await sut.refreshAllInvites(userId: userId1)
        remoteDatasource.stubbedGetPendingInvitesForUserResult = [invite2]
        try await sut.refreshAllInvites(userId: userId2)

        // When
        await sut.removeCachedInvite(userId: userId2, containing: sharedToken)

        // Then
        #expect(sut.currentPendingInvites.value[userId1] == [.user(invite1)])
        #expect(sut.currentPendingInvites.value[userId2]?.isEmpty == true)
    }
}

private extension UserInvite {
    static func random(inviteToken: String? = nil) -> UserInvite {
        .init(inviteToken: inviteToken ?? .random(),
              remindersSent: .random(in: 1...100),
              targetType: .random(in: 1...100),
              targetID: .random(),
              inviterEmail: .random(),
              invitedEmail: .random(),
              invitedAddressID: .random(),
              keys: [.init(key: .random(), keyRotation: .random(in: 1...100))],
              vaultData: .init(content: .random(),
                               contentKeyRotation: .random(in: 1...100),
                               contentFormatVersion: .random(in: 1...100),
                               memberCount: .random(in: 1...100),
                               itemCount: .random(in: 1...100)),
              fromNewUser: .random(),
              createTime: .random(in: 1...100))
    }
}
