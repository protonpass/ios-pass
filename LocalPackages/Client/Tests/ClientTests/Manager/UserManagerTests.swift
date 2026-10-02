//
// UserManagerTests.swift
// Proton Pass - Created on 16/05/2024.
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
import ClientMocks
import CoreMocks
import Entities
import ProtonCoreLogin
import Testing

@Suite(.tags(.manager))
struct UserManagerTests {
    private let userDataDatasource = LocalUserDataDatasourceProtocolMock()
    private let sut: any UserManagerProtocol

    init() {
        sut = UserManager(userDataDatasource: userDataDatasource,
                          logManager: LogManagerProtocolMock())
    }
}

private extension [UserProfile] {
    mutating func markLastProfileActive() {
        guard !self.isEmpty else { return }

        for index in 0..<self.count {
            self[index] = self[index].copy(isActive: index == self.count - 1)
        }
    }
}

extension UserManagerTests {
    @Test func `setting up loads all users with the active one first`() async throws {
        var mockedUserDatas = [UserProfile].random(randomElement: .randomInactive())
        mockedUserDatas.markLastProfileActive()
        let mockedUserIds = mockedUserDatas
            .sorted(by: { $0.isActive && !$1.isActive })
            .map(\.userdata.user.ID)
        userDataDatasource.stubbedGetAllResult = mockedUserDatas

        let mockedActiveUserId = try #require(mockedUserDatas.last).userdata.user.ID

        try await sut.setUp()
        let allUsers = try await sut.getAllUsers()
        let userIds = allUsers.map(\.user.ID)
        #expect(userIds == mockedUserIds)
        #expect(sut.activeUserId == mockedActiveUserId)
    }

    @Test func `active user data throws when users exist but none is active`() async throws {
        userDataDatasource.stubbedGetAllResult = [UserProfile.randomInactive()]

        try await sut.setUp()

        await #expect(throws: PassError.userManager(.userDatasAvailableButNoActiveUserId)) {
            try await sut.getActiveUserData()
        }
    }

    @Test func `active user data is nil when there are no users`() async throws {
        userDataDatasource.stubbedGetAllResult = []
        try await sut.setUp()
        #expect(try await sut.getActiveUserData() == nil)
    }

    @Test func `active user data is the active profile`() async throws {
        var mockedUserDatas = [UserProfile].random(randomElement: .randomInactive())
        mockedUserDatas.markLastProfileActive()
        userDataDatasource.stubbedGetAllResult = mockedUserDatas

        try await sut.setUp()

        let activeUserData = try await sut.getActiveUserData()
        #expect(activeUserData?.user.ID == mockedUserDatas.last?.userdata.user.ID)
    }

    @Test func `an upserted user becomes the active user`() async throws {
        var allUserDatas = [UserProfile].random(randomElement: .randomInactive())

        userDataDatasource.closureGetAll = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }

        userDataDatasource.closureUpsert = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            if let newUserData = userDataDatasource.invokedUpsertParameters?.0 {
                allUserDatas.append(UserProfile(userdata: newUserData, isActive: false, updateTime: 0))
            }
        }

        userDataDatasource.closureUpdateNewActiveUser = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            if let newUserId = userDataDatasource.invokedUpdateNewActiveUserParameters?.0,
               let index = allUserDatas.firstIndex(where: { $0.userdata.user.ID == newUserId }) {
                allUserDatas[index] = allUserDatas[index].copy(isActive: true)
            }
        }

        let userData = UserData.random()
        try await sut.setUp()

        try await sut.upsertAndMarkAsActive(userData: userData)
        let activeUserData = try #require(await sut.getActiveUserData())
        let unwrappedUserData = try await sut.getUnwrappedActiveUserData()

        let allUsers = try await sut.getAllUsers()

        #expect(allUsers.count == allUserDatas.count)
        #expect(activeUserData.user.ID == userData.user.ID)
        #expect(sut.activeUserId == userData.user.ID)
        #expect(unwrappedUserData.user.ID == activeUserData.user.ID)
    }

    @Test func `removing an inactive user keeps the active user`() async throws {
        let inactiveUserData = UserProfile.randomInactive()
        let inactiveUserId = inactiveUserData.userdata.user.ID

        var allUserDatas = [UserProfile].random(randomElement: .randomInactive())
        allUserDatas.markLastProfileActive()
        allUserDatas.append(inactiveUserData)

        userDataDatasource.closureGetAll = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        userDataDatasource.closureRemove = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            if let userId = userDataDatasource.invokedRemoveParameters?.0 {
                allUserDatas.removeAll { $0.userdata.user.ID == userId }
            }
        }

        try await sut.setUp()

        try await sut.remove(userId: inactiveUserId)

        let getAllUsers = try await sut.getAllUsers()

        #expect(getAllUsers.count == allUserDatas.count)
        #expect(!getAllUsers.contains(where: { $0.user.ID == inactiveUserId }))
        #expect(sut.activeUserId == allUserDatas.last?.userdata.user.ID)
        #expect(sut.currentActiveUser.value?.user.ID == allUserDatas.last?.userdata.user.ID)
    }

    @Test func `removing the active user makes another user active`() async throws {
        var allUserDatas = [UserProfile].random(randomElement: .randomInactive())
        allUserDatas.markLastProfileActive()
        let activeUserId = try #require(allUserDatas.last).userdata.user.ID
        userDataDatasource.closureGetAll = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        userDataDatasource.closureRemove = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            if let userId = userDataDatasource.invokedRemoveParameters?.0 {
                allUserDatas.removeAll { $0.userdata.user.ID == userId }
            }
        }
        userDataDatasource.closureUpdateNewActiveUser = {
            allUserDatas[0] = allUserDatas[0].copy(isActive: true)
        }

        try await sut.setUp()

        try await sut.remove(userId: activeUserId)
        let getAllUsers = try await sut.getAllUsers()

        #expect(getAllUsers.count == allUserDatas.count)
        #expect(!getAllUsers.contains(where: { $0.user.ID == activeUserId }))
        #expect(sut.activeUserId == getAllUsers.first?.user.ID)
        #expect(sut.currentActiveUser.value?.user.ID == getAllUsers.first?.user.ID)
    }

    @Test func `switching the active user updates the active user id`() async throws {
        var allUserDatas = [UserProfile]()

        let user1 = UserData.random()
        let user2 = UserData.random()
        let user3 = UserData.random()

        userDataDatasource.closureGetAll = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }

        userDataDatasource.closureUpdateNewActiveUser = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            allUserDatas = allUserDatas.map { $0.copy(isActive: false) }
            if let newUserId = userDataDatasource.invokedUpdateNewActiveUserParameters?.0,
               let index = allUserDatas.firstIndex(where: { $0.userdata.user.ID == newUserId }) {
                allUserDatas[index] = allUserDatas[index].copy(isActive: true)
            }
        }

        userDataDatasource.closureUpsert = { [weak userDataDatasource] in
            guard let userDataDatasource else { return }
            if let newUserData = userDataDatasource.invokedUpsertParameters?.0 {
                allUserDatas.append(UserProfile(userdata: newUserData, isActive: false, updateTime: 0))
            }
        }

        try await sut.setUp()

        try await sut.upsertAndMarkAsActive(userData: user1)
        #expect(sut.activeUserId == user1.user.ID)

        try await sut.upsertAndMarkAsActive(userData: user2)
        #expect(sut.activeUserId == user2.user.ID)

        try await sut.upsertAndMarkAsActive(userData: user3)
        #expect(sut.activeUserId == user3.user.ID)

        try await sut.switchActiveUser(with: user1.user.ID, onMemory: false)
        #expect(sut.activeUserId == user1.user.ID)
    }
}

private extension UserProfile {
    static func randomInactive() -> UserProfile {
        UserProfile(userdata: .random(), isActive: false, updateTime: 0)
    }

    func copy(isActive: Bool) -> UserProfile {
        UserProfile(userdata: userdata, isActive: isActive, updateTime: updateTime)
    }
}
