//
// Array+SymmetricallyEncryptedItemSortTests.swift
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

@testable import Client
import Entities
import EntitiesMocks
import Testing

@Suite(.tags(.utilities))
struct ArrayPlusSymmetricallyEncryptedItemSortTests {
    @Test func `items sort by last use time then modify time descending`() {
        let item1 = SymmetricallyEncryptedItem.random(item: .random(itemId: .random(),
                                                                    lastUseTime: 777,
                                                                    modifyTime: 444))
        let item2 = SymmetricallyEncryptedItem.random(item: .random(itemId: .random(),
                                                                    lastUseTime: 777,
                                                                    modifyTime: 111))
        let item3 = SymmetricallyEncryptedItem.random(item: .random(itemId: .random(),
                                                                    lastUseTime: 777,
                                                                    modifyTime: 333))
        let item4 = SymmetricallyEncryptedItem.random(item: .random(itemId: .random(),
                                                                    lastUseTime: 666,
                                                                    modifyTime: 222))
        let item5 = SymmetricallyEncryptedItem.random(item: .random(itemId: .random(),
                                                                    lastUseTime: 666,
                                                                    modifyTime: 555))
        let item6 = SymmetricallyEncryptedItem.random(item: .random(itemId: .random(),
                                                                    lastUseTime: 666,
                                                                    modifyTime: 666))
        let unsortedArray = [item1, item2, item3, item4, item5, item6]

        let sortedArray = unsortedArray.sorted()

        #expect(sortedArray[0].item.itemID == item1.item.itemID)
        #expect(sortedArray[1].item.itemID == item3.item.itemID)
        #expect(sortedArray[2].item.itemID == item2.item.itemID)
        #expect(sortedArray[3].item.itemID == item6.item.itemID)
        #expect(sortedArray[4].item.itemID == item5.item.itemID)
        #expect(sortedArray[5].item.itemID == item4.item.itemID)
    }

    @Test func `scored items sort by match score then modify time descending`() {
        let item1 = ScoredSymmetricallyEncryptedItem(item: .random(item: .random(itemId: .random(),
                                                                                 lastUseTime: 777,
                                                                                 modifyTime: 444)),
                                                     matchScore: 995)
        let item2 = ScoredSymmetricallyEncryptedItem(item: .random(item: .random(itemId: .random(),
                                                                                 lastUseTime: 777,
                                                                                 modifyTime: 111)),
                                                     matchScore: 995)
        let item3 = ScoredSymmetricallyEncryptedItem(item: .random(item: .random(itemId: .random(),
                                                                                 lastUseTime: 777,
                                                                                 modifyTime: 333)),
                                                     matchScore: 1_000)
        let unsortedArray = [item1, item2, item3]

        let sortedArray = unsortedArray.sorted()

        #expect(sortedArray[0].item.item.itemID == item3.item.item.itemID)
        #expect(sortedArray[1].item.item.itemID == item1.item.item.itemID)
        #expect(sortedArray[2].item.item.itemID == item2.item.item.itemID)
    }
}
