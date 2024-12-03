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
    public let loginWith2fa: Int
    public let alias: Int
    public let creditCard: Int
    public let note: Int
    public let identity: Int
    public let sharedByMe: Int
    public let sharedWithMe: Int

    public static let zero = ItemCount(total: 0,
                                       login: 0,
                                       loginWith2fa: 0,
                                       alias: 0,
                                       creditCard: 0,
                                       note: 0,
                                       identity: 0,
                                       sharedByMe: 0,
                                       sharedWithMe: 0)
}

public extension ItemCount {
    init(items: [any ItemTypeIdentifiable], sharedByMe: Int, sharedWithMe: Int) {
        total = items.count
        var login = 0
        var loginWith2fa = 0
        var alias = 0
        var creditCard = 0
        var note = 0
        var identity = 0

        for item in items {
            switch item.type {
            case .alias:
                alias += 1
            case .creditCard:
                creditCard += 1
            case .identity:
                identity += 1
            case .login:
                login += 1
                if item.totpUri?.isEmpty == false {
                    loginWith2fa += 1
                }
            case .note:
                note += 1
            }
        }

        self.login = login
        self.loginWith2fa = loginWith2fa
        self.alias = alias
        self.creditCard = creditCard
        self.note = note
        self.identity = identity
        self.sharedByMe = sharedByMe
        self.sharedWithMe = sharedWithMe
    }
}
