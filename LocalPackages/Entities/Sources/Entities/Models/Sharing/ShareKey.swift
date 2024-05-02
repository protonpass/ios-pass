//
// ShareKey.swift
// Proton Pass - Created on 19/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public struct ShareKey: Decodable, Hashable, Equatable, Sendable {
    public let createTime: Int64
    public let key: String
    public let keyRotation: Int64
    public let userKeyID: String

    public init(createTime: Int64, key: String, keyRotation: Int64, userKeyID: String) {
        self.createTime = createTime
        self.key = key
        self.keyRotation = keyRotation
        self.userKeyID = userKeyID
    }
}

public struct ShareKeys: Decodable, Sendable {
    public let total: Int
    public let keys: [ShareKey]

    public init(total: Int, keys: [ShareKey]) {
        self.total = total
        self.keys = keys
    }
}
