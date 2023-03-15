//
// ItemCount.swift
// Proton Pass - Created on 14/11/2022.
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

public protocol ItemContentTypeIdentifiable {
    var type: ItemContentType { get }
}

public struct ItemCount {
    public let loginCount: Int
    public let aliasCount: Int
    public let noteCount: Int

    public var total: Int { loginCount + aliasCount + noteCount }

    public static var zero = ItemCount(loginCount: 0, aliasCount: 0, noteCount: 0)

    public init(loginCount: Int, aliasCount: Int, noteCount: Int) {
        self.loginCount = loginCount
        self.aliasCount = aliasCount
        self.noteCount = noteCount
    }

    public init(items: [ItemContentTypeIdentifiable]) {
        self.loginCount = items.filter { $0.type == .login }.count
        self.aliasCount = items.filter { $0.type == .alias }.count
        self.noteCount = items.filter { $0.type == .note }.count
    }
}
