//
// ItemSortableTests.swift
// Proton Pass - Created on 09/03/2023.
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

@testable import Client
import Core
import Foundation
import Testing

// swiftlint:disable function_body_length
struct ItemSortableTests {
    @Test("Most recent sort")
    func mostRecentSort() throws {
        struct DummyItem: DateSortable {
            let dateForSorting: Date
        }

        var items = [DummyItem]()
        let now = Date()
        // Given today items
        let today1 = DummyItem(dateForSorting: now.adding(component: .second, value: -10))
        let today2 = DummyItem(dateForSorting: now.adding(component: .second, value: -1))
        let today3 = DummyItem(dateForSorting: now)

        items.append(contentsOf: [today1, today2, today3])

        // Given yesterday items
        let yesterdayDate = Date().adding(component: .day, value: -1)
        let yesterday1 = DummyItem(dateForSorting: yesterdayDate.adding(component: .second, value: -100))

        let yesterday2 = DummyItem(dateForSorting: yesterdayDate.adding(component: .second, value: -67))

        let yesterday3 = DummyItem(dateForSorting: yesterdayDate.adding(component: .second, value: -3))

        items.append(contentsOf: [yesterday1, yesterday2, yesterday3])

        // Given last 7 day items
        let last7Days1 = DummyItem(dateForSorting: now.adding(component: .day, value: -4))
        let last7Days2 = DummyItem(dateForSorting: now.adding(component: .day, value: -2))
        let last7Days3 = DummyItem(dateForSorting: now.adding(component: .day, value: -5))

        items.append(contentsOf: [last7Days1, last7Days2, last7Days3])

        // Given last 14 day items
        let last14Days1 = DummyItem(dateForSorting: now.adding(component: .day, value: -10))
        let last14Days2 = DummyItem(dateForSorting: now.adding(component: .day, value: -8))
        let last14Days3 = DummyItem(dateForSorting: now.adding(component: .day, value: -11))

        items.append(contentsOf: [last14Days1, last14Days2, last14Days3])

        // Given last 30 day items
        let last30Days1 = DummyItem(dateForSorting: now.adding(component: .day, value: -17))
        let last30Days2 = DummyItem(dateForSorting: now.adding(component: .day, value: -16))
        let last30Days3 = DummyItem(dateForSorting: now.adding(component: .day, value: -20))

        items.append(contentsOf: [last30Days1, last30Days2, last30Days3])

        // Given last 60 day items
        let last60Days1 = DummyItem(dateForSorting: now.adding(component: .day, value: -35))
        let last60Days2 = DummyItem(dateForSorting: now.adding(component: .day, value: -40))
        let last60Days3 = DummyItem(dateForSorting: now.adding(component: .day, value: -31))

        items.append(contentsOf: [last60Days1, last60Days2, last60Days3])

        // Given last 90 day items
        let last90Days1 = DummyItem(dateForSorting: now.adding(component: .day, value: -78))
        let last90Days2 = DummyItem(dateForSorting: now.adding(component: .day, value: -67))
        let last90Days3 = DummyItem(dateForSorting: now.adding(component: .day, value: -61))

        items.append(contentsOf: [last90Days1, last90Days2, last90Days3])

        // Given more than 90 day items
        let moreThan90Days1 = DummyItem(dateForSorting: now.adding(component: .year, value: -2))
        let moreThan90Days2 = DummyItem(dateForSorting: now.adding(component: .month, value: -8))
        let moreThan90Days3 = DummyItem(dateForSorting: now.adding(component: .day, value: -100))

        items.append(contentsOf: [moreThan90Days1, moreThan90Days2, moreThan90Days3])

        #expect(items.count == 24)

        items.shuffle()

        // When
        let sortResult = try items.mostRecentSortResult()

        // Then
        // Today
        let today = sortResult.buckets.first
        #expect(today?.type == .today)
        #expect(today?.items.count == 3)
        #expect(today?.items[0] == today3)
        #expect(today?.items[1] == today2)
        #expect(today?.items[2] == today1)

        // Yesterday

       let yesterday = sortResult.buckets[1]
        #expect(yesterday.type == .yesterday)
        #expect(yesterday.items.count == 3)
        assertEqual(yesterday.items[0], yesterday3)
        assertEqual(yesterday.items[1], yesterday2)
        assertEqual(yesterday.items[2], yesterday1)

        // Last 7 days
        let last7Days = sortResult.buckets[2]
        #expect(last7Days.type == .last7Days)
        #expect(last7Days.items.count == 3)
        assertEqual(last7Days.items[0], last7Days2)
        assertEqual(last7Days.items[1], last7Days1)
        assertEqual(last7Days.items[2], last7Days3)
        
        // Last 14 days
        let last14Days = sortResult.buckets[3]
        #expect(last14Days.type == .last14Days)
        #expect(last14Days.items.count == 3)
        assertEqual(last14Days.items[0], last14Days2)
        assertEqual(last14Days.items[1], last14Days1)
        assertEqual(last14Days.items[2], last14Days3)

        // Last 30 days
        let last30Days = sortResult.buckets[4]
        #expect(last30Days.type == .last30Days)
        #expect(last30Days.items.count == 3)
        assertEqual(last30Days.items[0], last30Days2)
        assertEqual(last30Days.items[1], last30Days1)
        assertEqual(last30Days.items[2], last30Days3)
        
        // Last 60 days
        let last60Days = sortResult.buckets[5]
        #expect(last60Days.type == .last60Days)
        #expect(last60Days.items.count == 3)
        assertEqual(last60Days.items[0], last60Days3)
        assertEqual(last60Days.items[1], last60Days1)
        assertEqual(last60Days.items[2], last60Days2)
        
        // Last 90 days
        let last90Days = sortResult.buckets[6]
        #expect(last90Days.type == .last90Days)
        #expect(last90Days.items.count == 3)
        assertEqual(last90Days.items[0], last90Days3)
        assertEqual(last90Days.items[1], last90Days2)
        assertEqual(last90Days.items[2], last90Days1)

        // Others
        let others = sortResult.buckets[7]
        #expect(others.type == .others)
        #expect(others.items.count == 3)
        assertEqual(others.items[0], moreThan90Days3)
        assertEqual(others.items[1], moreThan90Days2)
        assertEqual(others.items[2], moreThan90Days1)
    }

    func assertEqual(_ lhs: any DateSortable, _ rhs: any DateSortable) {
        #expect(lhs.dateForSorting == rhs.dateForSorting)
    }

    @Test("Alphabetical sort")
    func alphabeticalSort() throws {
        struct DummyItem: AlphabeticalSortable {
            let alphabeticalSortableString: String
        }

        // Given
        let strings: [String] = ["Chíp", "Touti", "Đen", "Ponyo", "Méo", "Pao", "Chippy"]
        let items = strings.map { DummyItem(alphabeticalSortableString: $0) }

        // When
        let sortResult = try items.alphabeticalSortResult(direction: .ascending)

        // Then
        #expect(sortResult.buckets.count == 5)

        let sharpBucket = sortResult.buckets[0]
        #expect(sharpBucket.items.count == 1)
        #expect(sharpBucket.items[0].alphabeticalSortableString == "Đen")

        let cBucket = sortResult.buckets[1]
        #expect(cBucket.items.count == 2)
        #expect(cBucket.items[0].alphabeticalSortableString == "Chippy")
        #expect(cBucket.items[1].alphabeticalSortableString == "Chíp")

        let mBucket = sortResult.buckets[2]
        #expect(mBucket.items.count == 1)
        #expect(mBucket.items[0].alphabeticalSortableString == "Méo")

        let pBucket = sortResult.buckets[3]
        #expect(pBucket.items.count == 2)
        #expect(pBucket.items[0].alphabeticalSortableString == "Pao")
        #expect(pBucket.items[1].alphabeticalSortableString == "Ponyo")

        let tBucket = sortResult.buckets[4]
        #expect(tBucket.items.count == 1)
        #expect(tBucket.items[0].alphabeticalSortableString == "Touti")
    }

    @Test("Alphabetical sort with numbers as prefix")
    func alphabeticalSortWithNumbersAsPrefix() throws {
        struct DummyItem: AlphabeticalSortable {
            let alphabeticalSortableString: String
        }

        // Given
        let strings: [String] = ["1 a", "3 b", "2 b", "1 b", "3 a", "2 a", "1 c"]
        let items = strings.map { DummyItem(alphabeticalSortableString: $0) }

        // When
        let sortResult = try items.alphabeticalSortResult(direction: .ascending)

        // Then
        #expect(sortResult.buckets.count == 1)

        let sharpBucket = sortResult.buckets[0]
        #expect(sharpBucket.items.count == 7)
        #expect(sharpBucket.items[0].alphabeticalSortableString == "1 a")
        #expect(sharpBucket.items[1].alphabeticalSortableString == "1 b")
        #expect(sharpBucket.items[2].alphabeticalSortableString == "1 c")
        #expect(sharpBucket.items[3].alphabeticalSortableString == "2 a")
        #expect(sharpBucket.items[4].alphabeticalSortableString == "2 b")
        #expect(sharpBucket.items[5].alphabeticalSortableString == "3 a")
        #expect(sharpBucket.items[6].alphabeticalSortableString == "3 b")
    }

    @Test("Month year sort")
    func monthYearSort() throws {
        struct DummyItem: DateSortable {
            let dateForSorting: Date
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let createDate: (String) -> Date = { dateFormat in
            dateFormatter.date(from: dateFormat)! // swiftlint:disable:this force_unwrapping
        }
        // Given
        let item1 = DummyItem(dateForSorting: createDate("11/03/2023"))
        let item2 = DummyItem(dateForSorting: createDate("20/03/2023"))
        let item3 = DummyItem(dateForSorting: createDate("01/07/2022"))
        let item4 = DummyItem(dateForSorting: createDate("05/03/2022"))
        let item5 = DummyItem(dateForSorting: createDate("18/03/2022"))
        let item6 = DummyItem(dateForSorting: createDate("18/06/2021"))

        let items = [item1, item2, item3, item4, item5, item6].shuffled()

        // When
        let sortedItemsDescending = try items.monthYearSortResult(direction: .descending)
        let sortedItemsAscending = try items.monthYearSortResult(direction: .ascending)

        // Then
        // Descending
        #expect(sortedItemsDescending.buckets.count == 4)

        #expect(sortedItemsDescending.buckets[0].items.count == 2)
        assertEqual(sortedItemsDescending.buckets[0].items[0], item2)
        assertEqual(sortedItemsDescending.buckets[0].items[1], item1)

        #expect(sortedItemsDescending.buckets[1].items.count == 1)
        assertEqual(sortedItemsDescending.buckets[1].items[0], item3)

        #expect(sortedItemsDescending.buckets[2].items.count == 2)
        assertEqual(sortedItemsDescending.buckets[2].items[0], item5)
        assertEqual(sortedItemsDescending.buckets[2].items[1], item4)

        #expect(sortedItemsDescending.buckets[3].items.count == 1)
        assertEqual(sortedItemsDescending.buckets[3].items[0], item6)

        // Ascending
        #expect(sortedItemsAscending.buckets.count == 4)

        #expect(sortedItemsAscending.buckets[0].items.count == 1)
        assertEqual(sortedItemsAscending.buckets[0].items[0], item6)

        #expect(sortedItemsAscending.buckets[1].items.count == 2)
        assertEqual(sortedItemsAscending.buckets[1].items[0], item4)
        assertEqual(sortedItemsAscending.buckets[1].items[1], item5)

        #expect(sortedItemsAscending.buckets[2].items.count == 1)
        assertEqual(sortedItemsAscending.buckets[2].items[0], item3)

        #expect(sortedItemsAscending.buckets[3].items.count == 2)
        assertEqual(sortedItemsAscending.buckets[3].items[0], item1)
        assertEqual(sortedItemsAscending.buckets[3].items[1], item2)
    }
}
