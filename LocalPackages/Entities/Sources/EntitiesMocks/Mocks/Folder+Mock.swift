//
// Folder+Mock.swift
// Proton Pass - Created on 02/02/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Entities

public extension Folder {
    static func random(vaultId: String? = nil,
                       folderId: String? = nil,
                       parentFolderId: String? = nil,
                       keyRotation: Int64? = nil,
                       folderKey: String? = nil,
                       contentFormatVersion: Int? = nil,
                       content: String? = nil) -> Folder {
        .init(vaultID: vaultId ?? .random(),
              folderID: folderId ?? .random(),
              parentFolderID: parentFolderId,
              keyRotation: keyRotation ?? .random(in: 1...100),
              folderKey: folderKey ?? .random(),
              contentFormatVersion: contentFormatVersion ?? .random(in: 1...10),
              content: content ?? .random())
    }
}
