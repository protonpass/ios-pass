//
// SymmetricallyEncryptedItem.swift
// Proton Pass - Created on 12/10/2022.
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

import CryptoKit
import Entities

/// Item with associated match score. Used in autofill context
public struct ScoredSymmetricallyEncryptedItem: Sendable {
    public let item: SymmetricallyEncryptedItem
    public let matchScore: Int

    public init(item: SymmetricallyEncryptedItem, matchScore: Int) {
        self.item = item
        self.matchScore = matchScore
    }
}

// https://sarunw.com/posts/how-to-sort-by-multiple-properties-in-swift/
private typealias AreInDecreasingOrder = (SymmetricallyEncryptedItem,
                                          SymmetricallyEncryptedItem) -> Bool

public extension [SymmetricallyEncryptedItem] {
    // swiftlint:disable opening_brace
    /// Sort by `lastUseTime` & `modifyTime` in decreasing order
    func sorted() -> Self {
        let predicates: [AreInDecreasingOrder] =
            [
                { ($0.item.lastUseTime ?? 0) > ($1.item.lastUseTime ?? 0) },
                { $0.item.modifyTime > $1.item.modifyTime }
            ]
        return sorted { lhs, rhs in
            for predicate in predicates {
                if !predicate(lhs, rhs), !predicate(rhs, lhs) {
                    continue
                }

                return predicate(lhs, rhs)
            }
            return false
        }
    }
}

extension SymmetricallyEncryptedItem: ItemIdentifiable {
    public var itemId: String { item.itemID }
}

private typealias ScoredAreInDecreasingOrder = (ScoredSymmetricallyEncryptedItem,
                                                ScoredSymmetricallyEncryptedItem) -> Bool

public extension [ScoredSymmetricallyEncryptedItem] {
    /// Sort by `lastUseTime` & `modifyTime` in decreasing order
    func sorted() -> Self {
        let predicates: [ScoredAreInDecreasingOrder] =
            [
                { $0.matchScore > $1.matchScore },
                { ($0.item.item.lastUseTime ?? 0) > ($1.item.item.lastUseTime ?? 0) },
                { $0.item.item.modifyTime > $1.item.item.modifyTime }
            ]
        return sorted { lhs, rhs in
            for predicate in predicates {
                if !predicate(lhs, rhs), !predicate(rhs, lhs) {
                    continue
                }

                return predicate(lhs, rhs)
            }
            return false
        }
    }
}

// swiftlint:enable opening_brace
