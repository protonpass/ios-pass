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

public struct VaultData: Decodable, Equatable, Hashable, Sendable {
    public let content: String
    public let contentKeyRotation: Int
    public let contentFormatVersion: Int
    public let memberCount: Int
    public let itemCount: Int

    public init(content: String,
                contentKeyRotation: Int,
                contentFormatVersion: Int,
                memberCount: Int,
                itemCount: Int) {
        self.content = content
        self.contentKeyRotation = contentKeyRotation
        self.contentFormatVersion = contentFormatVersion
        self.memberCount = memberCount
        self.itemCount = itemCount
    }
}

public extension VaultData {
    static var mocked: VaultData {
        VaultData(content: "contentId",
                  contentKeyRotation: 1,
                  contentFormatVersion: 2,
                  memberCount: 20,
                  itemCount: 65)
    }
}
