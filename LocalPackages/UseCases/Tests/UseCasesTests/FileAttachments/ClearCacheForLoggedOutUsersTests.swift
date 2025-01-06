//
// ClearCacheForLoggedOutUsersTests.swift
// Proton Pass - Created on 02/01/2025.
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

import ClientMocks
import Core
import Foundation
import ProtonCoreLogin
import Testing
import UseCases
import UseCasesMocks

struct ClearCacheForLoggedOutUsersTests {
    let datasource: LocalUserDataDatasourceProtocolMock
    let sut: any ClearCacheForLoggedOutUsersUseCase

    init() {
        let datasource = LocalUserDataDatasourceProtocolMock()
        self.datasource = datasource
        sut = ClearCacheForLoggedOutUsers(datasource: datasource)
    }

    @Test("Clear cached files for logged out users")
    func clear() async throws {
        // Given
        let fileManager = FileManager.default
        let user1 = UserData.random()
        let user2 = UserData.random()

        let user1Dir1 = try randomDir(for: user1)
        let user1Dir2 = try randomDir(for: user1)
        let user2Dir1 = try randomDir(for: user2)
        let user2Dir2 = try randomDir(for: user2)

        // When
        datasource.stubbedGetAllResult = [
            .init(userdata: user1, isActive: true, updateTime: 1),
            .init(userdata: user2, isActive: false, updateTime: 2)
        ]
        try await sut()

        // Then
        #expect(fileManager.fileExists(atPath: user1Dir1.path()))
        #expect(fileManager.fileExists(atPath: user1Dir2.path()))
        #expect(fileManager.fileExists(atPath: user2Dir1.path()))
        #expect(fileManager.fileExists(atPath: user2Dir2.path()))

        // When
        // Log out user2
        datasource.stubbedGetAllResult = [
            .init(userdata: user1, isActive: true, updateTime: 1)
        ]
        try await sut()

        // Then
        #expect(fileManager.fileExists(atPath: user1Dir1.path()))
        #expect(fileManager.fileExists(atPath: user1Dir2.path()))
        #expect(!fileManager.fileExists(atPath: user2Dir1.path()))
        #expect(!fileManager.fileExists(atPath: user2Dir2.path()))

        // When
        // Log out all users
        datasource.stubbedGetAllResult = []
        try await sut()

        // Then
        #expect(!fileManager.fileExists(atPath: user1Dir1.path()))
        #expect(!fileManager.fileExists(atPath: user1Dir2.path()))
        #expect(!fileManager.fileExists(atPath: user2Dir1.path()))
        #expect(!fileManager.fileExists(atPath: user2Dir2.path()))
    }

    func randomDir(for user: UserData) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: Constants.Attachment.rootDirectoryName)
            .appending(path: user.user.ID)
            .appending(path: String.random())
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
