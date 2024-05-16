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
import XCTest

final class LocalUserDataDatasourceTests: XCTestCase {
    var symmetricKeyProviderMockFactory: SymmetricKeyProviderMockFactory!
    var sut: LocalUserDataDatasourceProtocol!

    override func setUp() {
        super.setUp()
        symmetricKeyProviderMockFactory = .init()
        symmetricKeyProviderMockFactory.setUp()
        let symmetricKeyProvider = symmetricKeyProviderMockFactory.getProvider()
        sut = LocalUserDataDatasource(symmetricKeyProvider: symmetricKeyProvider,
                                      databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        symmetricKeyProviderMockFactory = nil
        sut = nil
        super.tearDown()
    }
}

extension LocalUserDataDatasourceTests {
    func testGetUpsertAndRemove() async throws {
        let userData1 = UserData.random()
        try await sut.upsert(userData1)
        let all1 = try await sut.getAll()
        XCTAssertEqual(all1.count, 1)
        XCTAssertEqual(all1.first?.user.ID, userData1.user.ID)

        let userData2 = UserData.random()
        try await sut.upsert(userData2)
        let all2 = try await sut.getAll()
        XCTAssertEqual(all2.count, 2)
        XCTAssertEqual(all2[0].user.ID, userData1.user.ID)
        XCTAssertEqual(all2[1].user.ID, userData2.user.ID)

        let userData3 = UserData.random()
        try await sut.upsert(userData3)
        let all3 = try await sut.getAll()
        XCTAssertEqual(all3.count, 3)
        XCTAssertEqual(all3[0].user.ID, userData1.user.ID)
        XCTAssertEqual(all3[1].user.ID, userData2.user.ID)
        XCTAssertEqual(all3[2].user.ID, userData3.user.ID)

        try await sut.remove(userId: userData2.user.ID)
        let all4 = try await sut.getAll()
        XCTAssertEqual(all4.count, 2)
        XCTAssertEqual(all4[0].user.ID, userData1.user.ID)
        XCTAssertEqual(all4[1].user.ID, userData3.user.ID)
    }
}
