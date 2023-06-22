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

public struct ItemCount {
    public let loginCount: Int
    public let aliasCount: Int
    public let creditCardCount: Int
    public let noteCount: Int

    public var total: Int {
        [loginCount, aliasCount, creditCardCount, noteCount].reduce(into: 0) { $0 += $1 }
    }

    public static var zero = ItemCount(loginCount: 0,
                                       aliasCount: 0,
                                       creditCardCount: 0,
                                       noteCount: 0)

    public init(loginCount: Int,
                aliasCount: Int,
                creditCardCount: Int,
                noteCount: Int) {
        self.loginCount = loginCount
        self.aliasCount = aliasCount
        self.creditCardCount = creditCardCount
        self.noteCount = noteCount
    }

    public init(items: [ItemTypeIdentifiable]) {
        loginCount = items.filter { $0.type == .login }.count
        aliasCount = items.filter { $0.type == .alias }.count
        creditCardCount = items.filter { $0.type == .creditCard }.count
        noteCount = items.filter { $0.type == .note }.count
    }
}
