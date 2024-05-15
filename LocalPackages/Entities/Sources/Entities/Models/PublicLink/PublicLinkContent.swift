//
// PublicLinkContent.swift
// Proton Pass - Created on 15/05/2024.
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

import Foundation

public struct PublicLinkContent: Decodable, Equatable, Sendable {
    public let contents, itemKey: String
    public let contentFormatVersion, expirationTime: Int
    public let readCount, maxReadCount: Int?

    public init(contents: String,
                itemKey: String,
                contentFormatVersion: Int,
                readCount: Int?,
                maxReadCount: Int?,
                expirationTime: Int) {
        self.contents = contents
        self.itemKey = itemKey
        self.contentFormatVersion = contentFormatVersion
        self.readCount = readCount
        self.maxReadCount = maxReadCount
        self.expirationTime = expirationTime
    }
}
