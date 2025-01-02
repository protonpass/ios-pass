//
// ClearCachedFiles.swift
// Proton Pass - Created on 31/12/2024.
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

import Client
import Core
import Foundation

public protocol ClearCachedFilesUseCase: Sendable {
    func execute() async throws
}

public extension ClearCachedFilesUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class ClearCachedFiles: ClearCachedFilesUseCase {
    private let userManager: any UserManagerProtocol

    public init(userManager: any UserManagerProtocol) {
        self.userManager = userManager
    }

    public func execute() async throws {
        let users = try await userManager.getAllUsers()
        let fileManager = FileManager.default
        for user in users {
            let url = fileManager.temporaryDirectory
                .appending(path: Constants.Attachment.rootDirectoryName)
                .appending(path: user.user.ID)
            if fileManager.fileExists(atPath: url.path()) {
                try fileManager.removeItem(at: url)
            }
        }
    }
}
