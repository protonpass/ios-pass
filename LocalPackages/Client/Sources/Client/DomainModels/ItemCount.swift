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

import Entities
import Foundation

public struct ItemCount: Hashable, Equatable, Sendable {
    public let total: Int
    public let login: Int
    public let alias: Int
    public let creditCard: Int
    public let note: Int

    public static let zero = ItemCount(total: 0,
                                       login: 0,
                                       alias: 0,
                                       creditCard: 0,
                                       note: 0)
}

public extension ItemCount {
    init(items: [any ItemTypeIdentifiable]) {
        total = items.count
        login = items.filter { $0.type == .login }.count
        alias = items.filter { $0.type == .alias }.count
        creditCard = items.filter { $0.type == .creditCard }.count
        note = items.filter { $0.type == .note }.count
    }
}
