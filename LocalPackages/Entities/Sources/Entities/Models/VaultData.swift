//
// VaultData.swift
// Proton Pass - Created on 20/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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

public struct VaultData: Decodable {
    public let itemID: String
    public let revision: Int16
    public let contentFormatVersion: Int16
    public let keyRotation: Int64
    public let content: String
    public let createTime: Int64
    public let modifyTime: Int64
    public let revisionTime: Int64

    enum CodingKeys: String, CodingKey {
        case itemID = "ItemID"
        case revision = "Revision"
        case contentFormatVersion = "ContentFormatVersion"
        case keyRotation = "KeyRotation"
        case content = "Content"
        case createTime = "CreateTime"
        case modifyTime = "ModifyTime"
        case revisionTime = "RevisionTime"
    }
}
