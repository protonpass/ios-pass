//
// LocalUserInviteDatasourceTests.swift
// Proton Pass - Created on 30/07/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Entities
import Testing

@Suite(.tags(.localDatasource))
struct LocalUserInviteDatasourceTests {
    let sut: any LocalUserInviteDatasourceProtocol

    init() {
        let databaseService = DatabaseService(inMemory: true)
        let inviteKeyDatasource = LocalInviteKeyDatasource(databaseService: databaseService)
        sut = LocalUserInviteDatasource(inviteKeyDatasource: inviteKeyDatasource,
                                        databaseService: databaseService)
    }

    @Test("Insert and get user invites")
    func insertAndGet() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        let invite1 = UserInvite.random()
        let invite2 = UserInvite.random()
        let invite3 = UserInvite.random()
        let invite4 = UserInvite.random()

        // When
        try await sut.upsertInvites(userId: userId1, invites: [invite1, invite2])
        try await sut.upsertInvites(userId: userId2, invites: [invite3, invite4])

        let invites1 = try await sut.getInvites(userId: userId1)
        let invites2 = try await sut.getInvites(userId: userId2)

        // Then
        #expect(invites1.count == 2)
        #expect(invites1.contains(invite1))
        #expect(invites1.contains(invite2))

        #expect(invites2.count == 2)
        #expect(invites2.contains(invite3))
        #expect(invites2.contains(invite4))
    }

    @Test("Upsert user invites")
    func upsert() async throws {
        // Given
        let userId = String.random()
        let invite = UserInvite.random()
        let updatedInvite = UserInvite.random(inviteToken: invite.inviteToken)

        // When
        try await sut.upsertInvites(userId: userId, invites: [invite])
        try await sut.upsertInvites(userId: userId, invites: [updatedInvite])
        let finalInvites = try await sut.getInvites(userId: userId)

        // Then
        #expect(finalInvites.count == 1)
        #expect(finalInvites.contains(updatedInvite))
    }

    @Test("Remove by userID and invites")
    func removeByUserIdAndInvite() async throws {
        // Given
        let userId = String.random()
        let invite = UserInvite.random()

        // When
        try await sut.upsertInvites(userId: userId, invites: [invite])
        try await sut.removeInvites(userId: userId, invites: [invite])
        let finalInvites = try await sut.getInvites(userId: userId)

        // Then
        #expect(finalInvites.isEmpty)
    }

    @Test("Remove by userID")
    func removeByUserId() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        try await sut.upsertInvites(userId: userId1, invites: [.random(), .random()])
        try await sut.upsertInvites(userId: userId2, invites: [.random(), .random(), .random()])

        // When
        try await sut.removeInvites(userId: userId1)
        let invites1 = try await sut.getInvites(userId: userId1)
        let invites2 = try await sut.getInvites(userId: userId2)

        // Then
        #expect(invites1.isEmpty)
        #expect(invites2.count == 3)
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
