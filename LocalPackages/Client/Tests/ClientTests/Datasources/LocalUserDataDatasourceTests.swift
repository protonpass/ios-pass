//
// LocalUserDataDatasourceTests.swift
// Proton Pass - Created on 14/05/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import CryptoKit
import ProtonCoreLogin
import Testing

@Suite(.tags(.localDatasource))
struct LocalUserDataDatasourceTests {
    let sut: any LocalUserDataDatasourceProtocol

    init() {
        let symmetricKeyProviderMockFactory = SymmetricKeyProviderMockFactory()
        symmetricKeyProviderMockFactory.setUp()
        sut = LocalUserDataDatasource(symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                      databaseService: DatabaseService(inMemory: true))
    }

    @Test func `users are returned in insertion order and can be removed`() async throws {
        let userData1 = UserData.random()
        try await sut.upsert(userData1)
        let all1 = try await sut.getAll()
        #expect(all1.count == 1)
        #expect(all1.first?.userdata.user.ID == userData1.user.ID)

        let userData2 = UserData.random()
        try await sut.upsert(userData2)
        let all2 = try await sut.getAll()
        #expect(all2.count == 2)
        #expect(all2[0].userdata.user.ID == userData1.user.ID)
        #expect(all2[1].userdata.user.ID == userData2.user.ID)

        let userData3 = UserData.random()
        try await sut.upsert(userData3)
        let all3 = try await sut.getAll()
        #expect(all3.count == 3)
        #expect(all3[0].userdata.user.ID == userData1.user.ID)
        #expect(all3[1].userdata.user.ID == userData2.user.ID)
        #expect(all3[2].userdata.user.ID == userData3.user.ID)

        try await sut.remove(userId: userData2.user.ID)
        let all4 = try await sut.getAll()
        #expect(all4.count == 2)
        #expect(all4[0].userdata.user.ID == userData1.user.ID)
        #expect(all4[1].userdata.user.ID == userData3.user.ID)
    }

    @Test func `the active user only changes when explicitly updated`() async throws {
        let userData1 = UserData.random()
        try await sut.upsert(userData1)
        let noActiveUser = try await sut.getActiveUser()
        #expect(noActiveUser == nil)

        try await sut.updateNewActiveUser(userId: userData1.user.ID)
        let activeUser1 = try #require(await sut.getActiveUser())
        #expect(activeUser1.isActive)
        #expect(activeUser1.userdata.user.ID == userData1.user.ID)

        let userData2 = UserData.random()
        try await sut.upsert(userData2)
        let activeUser = try #require(await sut.getActiveUser())

        #expect(activeUser.userdata.user.ID == userData1.user.ID)

        try await sut.updateNewActiveUser(userId: userData2.user.ID)
        let activeUser2 = try #require(await sut.getActiveUser())
        #expect(activeUser2.isActive)
        #expect(activeUser2.userdata.user.ID == userData2.user.ID)
    }
}
