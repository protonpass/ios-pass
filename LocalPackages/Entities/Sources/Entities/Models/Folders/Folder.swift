//
// Folder.swift
// Proton Pass - Created on 01/12/2025.
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

import Foundation

public struct Folder: Codable, Sendable, Identifiable, Equatable, Hashable {
    public let vaultID: String
    public let folderID: String
    public let parentFolderID: String?
    public let keyRotation: Int
    public let folderKey: String
    public let contentFormatVersion: Int
    public let content: String

    public var id: String {
        folderID
    }

    public init(vaultID: String,
                folderID: String,
                parentFolderID: String?,
                keyRotation: Int,
                folderKey: String,
                contentFormatVersion: Int,
                content: String) {
        self.vaultID = vaultID
        self.folderID = folderID
        self.parentFolderID = parentFolderID
        self.keyRotation = keyRotation
        self.folderKey = folderKey
        self.contentFormatVersion = contentFormatVersion
        self.content = content
    }
}
