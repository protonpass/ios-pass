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
    var activeUserIdDatasource: LocalActiveUserIdDatasourceProtocolMock!
    var sut: UserManagerProtocol!

    override func setUp() {
        super.setUp()
        userDataDatasource = .init()
        activeUserIdDatasource = .init()
        sut = UserManager(userDataDatasource: userDataDatasource,
                          activeUserIdDatasource: activeUserIdDatasource,
                          logManager: LogManagerProtocolMock())
    }

    override func tearDown() {
        userDataDatasource = nil
        activeUserIdDatasource = nil
        sut = nil
        super.tearDown()
    }
}

extension UserManagerTests {
    func testSetUp() async throws {
        let mockedUserDatas = [UserData].random(randomElement: .random())
        let mockedUserIds = mockedUserDatas.map(\.user.ID)
        userDataDatasource.stubbedGetAllResult = mockedUserDatas

        let mockedActiveUserId = mockedUserIds.first!
        activeUserIdDatasource.stubbedGetActiveUserIdResult = mockedActiveUserId

        try await sut.setUp()
        let allUsers = try await sut.getAllUser()
        let userIds = allUsers.map(\.user.ID)
        XCTAssertEqual(userIds, mockedUserIds)
        XCTAssertEqual(sut.activeUserId, mockedActiveUserId)
    }

//    func testGetActiveUserData_ThrowUserDatasAvailableButNoActiveUserId() async throws {
//        let expectation = expectation(description: "Should throw error")
//
//        userDataDatasource.stubbedGetAllResult = .random(randomElement: .random())
//        activeUserIdDatasource.stubbedGetActiveUserIdResult = nil
//        try await sut.setUp()
//
//        do {
//            _ = try await sut.getActiveUserData()
//        } catch {
//            if error.isEqual(to: .userDatasAvailableButNoActiveUserId) {
//                expectation.fulfill()
//            } else {
//                XCTFail("Unexpected error")
//            }
//        }
//
//        await fulfillment(of: [expectation], timeout: 1)
//    }

    func testGetActiveUserData_ThrowActiveUserIdAvailableButNoUserDataFound() async throws {
        let expectation = expectation(description: "Should throw error")

        userDataDatasource.stubbedGetAllResult = []
        activeUserIdDatasource.stubbedGetActiveUserIdResult = .random()
        try await sut.setUp()

        do {
            _ = try await sut.getActiveUserData()
        } catch {
            if error.isEqual(to: .activeUserIdAvailableButNoUserDataFound) {
                expectation.fulfill()
            } else {
                XCTFail("Unexpected error")
            }
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testGetActiveUserData_IfNoActiveUserDataNotFound_ReturnTheFirstOfOthers() async throws {
        userDataDatasource.stubbedGetAllResult = .random(randomElement: .random())
        activeUserIdDatasource.stubbedGetActiveUserIdResult = .random()
        try await sut.setUp()

        let newActiveUser = try await sut.getActiveUserData()
        XCTAssertEqual(newActiveUser?.user.ID, userDataDatasource.stubbedGetAllResult.first?.user.ID)
        XCTAssertEqual(sut.activeUserId, newActiveUser?.user.ID)
    }
    
    
//    func testGetActiveUserData_ThrowActiveUserDataNotFound() async throws {
//        let expectation = expectation(description: "Should throw error")
//
//        userDataDatasource.stubbedGetAllResult = .random(randomElement: .random())
//        activeUserIdDatasource.stubbedGetActiveUserIdResult = .random()
//        try await sut.setUp()
//
//        do {
//            _ = try await sut.getActiveUserData()
//        } catch {
//            if error.isEqual(to: .activeUserDataNotFound) {
//                expectation.fulfill()
//            } else {
//                XCTFail("Unexpected error")
//            }
//        }
//
//        await fulfillment(of: [expectation], timeout: 1)
//    }

    func testGetActiveUserData() async throws {
        let mockedUserDatas = [UserData].random(randomElement: .random())
        let givenActiveUserData = try XCTUnwrap(mockedUserDatas.randomElement())
        userDataDatasource.stubbedGetAllResult = mockedUserDatas
        activeUserIdDatasource.stubbedGetActiveUserIdResult = givenActiveUserData.user.ID

        try await sut.setUp()

        let activeUserData = try await sut.getActiveUserData()
        XCTAssertEqual(activeUserData?.user.ID, givenActiveUserData.user.ID)
    }

    func testAddAndMarkAsActive() async throws {
        // Given
        var allUserDatas = [UserData].random(randomElement: .random())
        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        userDataDatasource.closureUpsert = { [weak self] in
            guard let self else { return }
            if let newUserData = userDataDatasource.invokedUpsertParameters?.0 {
                allUserDatas.append(newUserData)
            }
        }

        var activeUserId: String?
        activeUserIdDatasource.closureGetActiveUserId = { [weak self] in
            guard let self else { return }
            activeUserIdDatasource.stubbedGetActiveUserIdResult = activeUserId
        }
        activeUserIdDatasource.closureUpdateActiveUserId = { [weak self] in
            guard let self else { return }
            activeUserId = activeUserIdDatasource.invokedUpdateActiveUserIdParameters?.0
        }

        let userData = UserData.random()
        try await sut.setUp()

        // When
        try await sut.addAndMarkAsActive(userData: userData)
        let activeUserData = try await XCTUnwrapAsync(await sut.getActiveUserData())

        let allUsers = try await sut.getAllUser()
        // Then
        XCTAssertEqual(allUsers.count, allUserDatas.count)
        XCTAssertEqual(activeUserData.user.ID, userData.user.ID)
        XCTAssertEqual(sut.activeUserId, userData.user.ID)
    }

    func testRemoveActiveUser() async throws {
        // Given
        let activeUserData = UserData.random()
        let activeUserId = activeUserData.user.ID
        var allUserDatas = [UserData].random(randomElement: .random())
        allUserDatas.append(activeUserData)

        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        userDataDatasource.closureRemove = { [weak self] in
            guard let self else { return }
            if let userId = userDataDatasource.invokedRemoveParameters?.0 {
                allUserDatas.removeAll { $0.user.ID == userId }
            }
        }

        activeUserIdDatasource.stubbedGetActiveUserIdResult = activeUserId
        try await sut.setUp()

        // When
        try await sut.remove(userId: activeUserId)
        let getAllUsers = try await sut.getAllUser()

        // Then
        XCTAssertEqual(getAllUsers.count, allUserDatas.count)
        XCTAssertFalse(getAllUsers.contains(where: { $0.user.ID == activeUserId }))
        XCTAssertEqual(sut.activeUserId, getAllUsers.first!.user.ID)
    }

    func testRemoveInactiveUser() async throws {
        // Given
        let inactiveUserData = UserData.random()
        let inactiveUserId = inactiveUserData.user.ID
        var allUserDatas = [UserData].random(randomElement: .random())
        allUserDatas.append(inactiveUserData)

        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        userDataDatasource.closureRemove = { [weak self] in
            guard let self else { return }
            if let userId = userDataDatasource.invokedRemoveParameters?.0 {
                allUserDatas.removeAll { $0.user.ID == userId }
            }
        }

        let mockedActiveUserId = allUserDatas.first!.user.ID
        activeUserIdDatasource.stubbedGetActiveUserIdResult = mockedActiveUserId
//        let activeUserId = String.random()
//        activeUserIdDatasource.stubbedGetActiveUserIdResult = activeUserId
        try await sut.setUp()

        // When
        try await sut.remove(userId: inactiveUserId)

        let getAllUsers = try await sut.getAllUser()

        // Then
        XCTAssertEqual(getAllUsers.count, allUserDatas.count)
        XCTAssertFalse(getAllUsers.contains(where: { $0.user.ID == inactiveUserId }))
        XCTAssertEqual(sut.activeUserId, mockedActiveUserId)
    }
    
    
    func testSwitchActiveUser() async throws {
        // Given
        let User1 = UserData.random()
        let User2 = UserData.random()
        let User3 = UserData.random()
        var allUserDatas: [UserData] = []
        userDataDatasource.closureGetAll = { [weak self] in
            guard let self else { return }
            userDataDatasource.stubbedGetAllResult = allUserDatas
        }
        try await sut.setUp()
     
        try await sut.addAndMarkAsActive(userData: User1)
        
        
        XCTAssertEqual(sut.activeUserId, User1.user.ID)
        
        try await sut.addAndMarkAsActive(userData: User2)
        
        
        XCTAssertEqual(sut.activeUserId, User2.user.ID)
        
        try await sut.addAndMarkAsActive(userData: User3)
        
        
        XCTAssertEqual(sut.activeUserId, User3.user.ID)
        
        allUserDatas.append(contentsOf: [User1,User2,User3])
        try await sut.switchActiveUser(with: User1.user.ID)
        XCTAssertEqual(sut.activeUserId, User1.user.ID)
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

