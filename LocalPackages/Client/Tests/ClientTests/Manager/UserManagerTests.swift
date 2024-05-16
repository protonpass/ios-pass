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

        let mockedActiveUserId = String.random()
        activeUserIdDatasource.stubbedGetActiveUserIdResult = mockedActiveUserId

        try await sut.setUp()
        let userIds = sut.userDatas.value.map(\.user.ID)
        XCTAssertEqual(userIds, mockedUserIds)
    }

    func testGetActiveUserData_ThrowUserDatasAvailableButNoActiveUserId() async throws {
        let expectation = XCTestExpectation(description: "Should throw error")

        userDataDatasource.stubbedGetAllResult = .random(randomElement: .random())
        activeUserIdDatasource.stubbedGetActiveUserIdResult = nil
        try await sut.setUp()

        do {
            _ = try await sut.getActiveUserData()
        } catch {
            if error.isEqual(to: .userDatasAvailableButNoActiveUserId) {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testGetActiveUserData_ThrowActiveUserIdAvailableButNoUserDataFound() async throws {
        let expectation = XCTestExpectation(description: "Should throw error")

        userDataDatasource.stubbedGetAllResult = []
        activeUserIdDatasource.stubbedGetActiveUserIdResult = .random()
        try await sut.setUp()

        do {
            _ = try await sut.getActiveUserData()
        } catch {
            if error.isEqual(to: .activeUserIdAvailableButNoUserDataFound) {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testGetActiveUserData_ThrowActiveUserDataNotFound() async throws {
        let expectation = XCTestExpectation(description: "Should throw error")

        userDataDatasource.stubbedGetAllResult = .random(randomElement: .random())
        activeUserIdDatasource.stubbedGetActiveUserIdResult = .random()
        try await sut.setUp()

        do {
            _ = try await sut.getActiveUserData()
        } catch {
            if error.isEqual(to: .activeUserDataNotFound) {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

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

        // Then
        XCTAssertEqual(sut.userDatas.value.count, allUserDatas.count)
        XCTAssertEqual(activeUserData.user.ID, userData.user.ID)
        XCTAssertEqual(sut.activeUserId.value, userData.user.ID)
    }

    func testRemoveLastUser_ReturnNoOtherActiveUser() async throws {
        // Given
        let singleActiveUserData = UserData.random()
        let singleActiveUserId = singleActiveUserData.user.ID
        var allUserDatas: [UserData] = [singleActiveUserData]

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

        activeUserIdDatasource.stubbedGetActiveUserIdResult = singleActiveUserId
        try await sut.setUp()

        // When
        let result = try await sut.remove(userId: singleActiveUserId)

        // Then
        XCTAssertNil(result)
    }

    func testRemoveUser_ReturnAnotherActiveUser() async throws {
        // Given
        let activeUserData = UserData.random()
        let activeUserId = activeUserData.user.ID
        let inactiveUserData = UserData.random()
        var allUserDatas: [UserData] = [activeUserData, inactiveUserData]

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
        let result = try await sut.remove(userId: activeUserId)

        // Then
        XCTAssertEqual(result?.user.ID, inactiveUserData.user.ID)
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
