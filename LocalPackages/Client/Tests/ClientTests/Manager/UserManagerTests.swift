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
import XCTest

final class UserManagerTests: XCTestCase {
    var userDataDatasource: LocalUserDataDatasourceProtocolMock!
    var sut: UserManagerProtocol!
    
    override func setUp() {
        super.setUp()
        userDataDatasource = .init()
        sut = UserManager(userDataDatasource: userDataDatasource,
                          logManager: LogManagerProtocolMock())
    }
    
    override func tearDown() {
        userDataDatasource = nil
        sut = nil
        super.tearDown()
    }
}

private extension [UserProfile] {
    mutating func markLastProfileActive() {
        guard !self.isEmpty else { return }
        
        for index in 0..<self.count {
            self[index] = self[index].copy(isActive: (index == self.count - 1))
        }
    }
}

extension UserManagerTests {
    func testSetUp() async throws {
        var mockedUserDatas = [UserProfile].random(randomElement: UserProfile(userdata: .random(), isActive: false, updateTime: 0))
        mockedUserDatas.markLastProfileActive()
        let mockedUserIds = mockedUserDatas
            .sorted(by: { $0.isActive && !$1.isActive })
            .map(\.userdata.user.ID)
        userDataDatasource.stubbedGetAllResult = mockedUserDatas
        
        let mockedActiveUserId = mockedUserDatas.last!.userdata.user.ID
        
        try await sut.setUp()
        let allUsers = try await sut.getAllUsers()
        let userIds = allUsers.map(\.user.ID)
        XCTAssertEqual(userIds, mockedUserIds)
        XCTAssertEqual(sut.activeUserId, mockedActiveUserId)
    }
    
    func testGetActiveUserData_ThrowUserDatasAvailableButNoActiveUserId() async throws {
        let expectation = expectation(description: "Should throw error")
        
        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = [UserProfile(userdata: .random(), isActive: false, updateTime: 0)]
        }
        
        try await sut.setUp()
        
        do {
            _ = try await sut.getActiveUserData()
        } catch {
            if error.isEqual(to: .userDatasAvailableButNoActiveUserId) {
                expectation.fulfill()
            } else {
                XCTFail("Unexpected error")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func testGetActiveUserData_FoundNil() async throws {
        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = []
        }
        try await sut.setUp()
        try await XCTAssertNilAsync(await sut.getActiveUserData())
    }
    
    func testGetActiveUserData() async throws {
        var mockedUserDatas = [UserProfile].random(randomElement: UserProfile(userdata: .random(), isActive: false, updateTime: 0))
        mockedUserDatas.markLastProfileActive()
        userDataDatasource.stubbedGetAllResult = mockedUserDatas
        
        try await sut.setUp()
        
        let activeUserData = try await sut.getActiveUserData()
        XCTAssertEqual(activeUserData?.user.ID, mockedUserDatas.last?.userdata.user.ID)
    }
    
    func testUpsertAndMarkAsActive() async throws {
        // Given
        var allUserDatas = [UserProfile].random(randomElement: UserProfile(userdata: .random(), isActive: false, updateTime: 0))
        
        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        
        userDataDatasource.closureUpsert = { [weak self] in
            guard let self else { return }
            if let newUserData = userDataDatasource.invokedUpsertParameters?.0 {
                allUserDatas.append(UserProfile(userdata: newUserData, isActive: false, updateTime: 0) )
            }
        }
        
        userDataDatasource.closureUpdateNewActiveUser  = { [weak self] in
            guard let self else { return }
            if let newUserId = userDataDatasource.invokedUpdateNewActiveUserParameters?.0,
               let index = allUserDatas.firstIndex(where: { $0.userdata.user.ID == newUserId }) {
                allUserDatas[index] = allUserDatas[index].copy(isActive: true)
            }
        }
        
        let userData = UserData.random()
        try await sut.setUp()
        
        // When
        try await sut.upsertAndMarkAsActive(userData: userData)
        let activeUserData = try await XCTUnwrapAsync(await sut.getActiveUserData())
        let unwrappedUserData = try await sut.getUnwrappedActiveUserData()
        
        let allUsers = try await sut.getAllUsers()
        // Then
        XCTAssertEqual(allUsers.count, allUserDatas.count)
        XCTAssertEqual(activeUserData.user.ID, userData.user.ID)
        XCTAssertEqual(sut.activeUserId, userData.user.ID)
        XCTAssertEqual(unwrappedUserData.user.ID, activeUserData.user.ID)
    }
    
    func testRemoveInactiveUser() async throws {
        // Given
        let inactiveUserData = UserProfile(userdata: .random(), isActive: false, updateTime: 0)
        let inactiveUserId = inactiveUserData.userdata.user.ID
        
        
        var allUserDatas = [UserProfile].random(randomElement: UserProfile(userdata: .random(), isActive: false, updateTime: 0))
        allUserDatas.markLastProfileActive()
        allUserDatas.append(inactiveUserData)
        
        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        userDataDatasource.closureRemove = { [weak self] in
            guard let self else { return }
            if let userId = userDataDatasource.invokedRemoveParameters?.0 {
                allUserDatas.removeAll { $0.userdata.user.ID == userId }
            }
        }
        
        try await sut.setUp()
        
        // When
        try await sut.remove(userId: inactiveUserId)
        
        let getAllUsers = try await sut.getAllUsers()
        
        // Then
        XCTAssertEqual(getAllUsers.count, allUserDatas.count)
        XCTAssertFalse(getAllUsers.contains(where: { $0.user.ID == inactiveUserId }))
        XCTAssertEqual(sut.activeUserId, allUserDatas.last?.userdata.user.ID)
        XCTAssertEqual(sut.currentActiveUser.value?.user.ID, allUserDatas.last?.userdata.user.ID)
    }
    
    func testRemoveActiveUser() async throws {
        // Given
        var allUserDatas = [UserProfile].random(randomElement: UserProfile(userdata: .random(), isActive: false, updateTime: 0))
        allUserDatas.markLastProfileActive()
        let activeUserId = allUserDatas.last!.userdata.user.ID
        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        userDataDatasource.closureRemove = { [weak self] in
            guard let self else { return }
            if let userId = userDataDatasource.invokedRemoveParameters?.0 {
                allUserDatas.removeAll { $0.userdata.user.ID == userId }
            }
        }
        userDataDatasource.closureUpdateNewActiveUser  = {
            allUserDatas[0] = allUserDatas[0].copy(isActive: true)
        }
        
        try await sut.setUp()
        
        
        // When
        try await sut.remove(userId: activeUserId)
        let getAllUsers = try await sut.getAllUsers()
        
        // Then
        XCTAssertEqual(getAllUsers.count, allUserDatas.count)
        XCTAssertFalse(getAllUsers.contains(where: { $0.user.ID == activeUserId }))
        XCTAssertEqual(sut.activeUserId, getAllUsers.first?.user.ID)
        XCTAssertEqual(sut.currentActiveUser.value?.user.ID, getAllUsers.first?.user.ID)
    }
    
    func testSwitchActiveUser() async throws {
        // Given
        var allUserDatas = [UserProfile]()
        
        let user1 = UserData.random()
        let user2 = UserData.random()
        let user3 = UserData.random()
        
        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        
        userDataDatasource.closureUpdateNewActiveUser = { [weak self] in
            guard let self else { return }
            allUserDatas = allUserDatas.map { $0.copy(isActive: false) }
            if let newUserId = userDataDatasource.invokedUpdateNewActiveUserParameters?.0,
               let index = allUserDatas.firstIndex(where: { $0.userdata.user.ID == newUserId }) {
                allUserDatas[index] = allUserDatas[index].copy(isActive: true)
            }
        }
        
        userDataDatasource.closureUpsert = { [weak self] in
            guard let self else { return }
            if let newUserData = userDataDatasource.invokedUpsertParameters?.0 {
                allUserDatas.append( UserProfile(userdata: newUserData, isActive: false, updateTime: 0))
            }
        }
        
        try await sut.setUp()

        try await sut.upsertAndMarkAsActive(userData: user1)
        XCTAssertEqual(sut.activeUserId, user1.user.ID)

        try await sut.upsertAndMarkAsActive(userData: user2)
        XCTAssertEqual(sut.activeUserId, user2.user.ID)

        try await sut.upsertAndMarkAsActive(userData: user3)
        XCTAssertEqual(sut.activeUserId, user3.user.ID)

        try await sut.switchActiveUser(with: user1.user.ID, onMemory: false)
        XCTAssertEqual(sut.activeUserId, user1.user.ID)
    }
}

private extension Error {
    func isEqual(to reason: PassError.UserManagerFailureReason) -> Bool {
        if let passError = self as? PassError,
           case let .userManager(r) = passError,
           r == reason {
            return true
        }
        return false
    }
}
