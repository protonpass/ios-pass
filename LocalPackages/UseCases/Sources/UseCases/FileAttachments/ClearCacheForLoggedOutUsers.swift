//
// ClearCacheForLoggedOutUsers.swift
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

import Client
import Core
import Foundation

public protocol ClearCacheForLoggedOutUsersUseCase: Sendable {
    func execute() async throws
}

public extension ClearCacheForLoggedOutUsersUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class ClearCacheForLoggedOutUsers: ClearCacheForLoggedOutUsersUseCase {
    private let datasource: any LocalUserDataDatasourceProtocol

    public init(datasource: any LocalUserDataDatasourceProtocol) {
        self.datasource = datasource
    }

    public func execute() async throws {
        let fileManager = FileManager.default
        let rootDirectory = fileManager
            .temporaryDirectory
            .appending(path: Constants.Attachment.rootDirectoryName)
        let contents = try fileManager.contentsOfDirectory(at: rootDirectory,
                                                           includingPropertiesForKeys: [.isDirectoryKey],
                                                           options: .skipsHiddenFiles)

        // Filter only directories
        let directories = contents.filter { url in
            var isDirectory: ObjCBool = false
            return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }

        // Loop through all the directories and remove those of logged out users
        let users = try await datasource.getAll()
        let userIds = users.map(\.userdata.user.ID)
        for dir in directories where !userIds.contains(dir.lastPathComponent) {
            try fileManager.removeItem(at: dir)
        }
    }
}
