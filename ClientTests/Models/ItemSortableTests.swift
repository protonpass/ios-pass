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
import XCTest

// swiftlint:disable function_body_length
final class ItemSortableTests: XCTestCase {
    func testMostRecentSort() {
        struct DummyItem: MostRecentSortable {
            let lastUseTime: Int64
            let modifyTime: Int64
        }

        continueAfterFailure = false
        var items = [DummyItem]()
        let now = Date()
        // Given today items
        let today1 = DummyItem(lastUseTime: now.adding(.init(.second, -10)).time,
                               modifyTime: now.adding(.init(.day, -193)).time)
        let today2 = DummyItem(lastUseTime: now.adding(.init(.second, -1)).time,
                               modifyTime: now.adding(.init(.month, -18)).time)
        let today3 = DummyItem(lastUseTime: 0,
                               modifyTime: now.time)

        items.append(contentsOf: [today1, today2, today3])

        // Given yesterday items
        let yesterdayDate = Date().adding(.init(.day, -1))
        let yesterday1 = DummyItem(lastUseTime: yesterdayDate.adding(.init(.second, -100)).time,
                                   modifyTime: now.adding(.init(.month, -5)).time)

        let yesterday2 = DummyItem(lastUseTime: 0,
                                   modifyTime: yesterdayDate.adding(.init(.second, -67)).time)

        let yesterday3 = DummyItem(lastUseTime: yesterdayDate.adding(.init(.second, -3)).time,
                                   modifyTime: now.adding(.init(.month, -8)).time)

        items.append(contentsOf: [yesterday1, yesterday2, yesterday3])

        // Given last 7 day items
        let last7Days1 = DummyItem(lastUseTime: now.adding(.init(.day, -4)).time,
                                   modifyTime: now.adding(.init(.month, -10)).time)
        let last7Days2 = DummyItem(lastUseTime: 0,
                                   modifyTime: now.adding(.init(.day, -2)).time)
        let last7Days3 = DummyItem(lastUseTime: 0,
                                   modifyTime: now.adding(.init(.day, -5)).time)

        items.append(contentsOf: [last7Days1, last7Days2, last7Days3])

        // Given last 14 day items
        let last14Days1 = DummyItem(lastUseTime: 0,
                                    modifyTime: now.adding(.init(.day, -10)).time)
        let last14Days2 = DummyItem(lastUseTime: now.adding(.init(.day, -8)).time,
                                    modifyTime: now.adding(.init(.month, -2)).time)
        let last14Days3 = DummyItem(lastUseTime: now.adding(.init(.day, -11)).time,
                                    modifyTime: now.adding(.init(.day, -13)).time)

        items.append(contentsOf: [last14Days1, last14Days2, last14Days3])

        // Given last 30 day items
        let last30Days1 = DummyItem(lastUseTime: now.adding(.init(.day, -17)).time,
                                    modifyTime: now.adding(.init(.month, -2)).time)
        let last30Days2 = DummyItem(lastUseTime: 0,
                                    modifyTime: now.adding(.init(.day, -16)).time)
        let last30Days3 = DummyItem(lastUseTime: now.adding(.init(.day, -20)).time,
                                    modifyTime: now.adding(.init(.month, -18)).time)

        items.append(contentsOf: [last30Days1, last30Days2, last30Days3])

        // Given last 60 day items
        let last60Days1 = DummyItem(lastUseTime: now.adding(.init(.day, -35)).time,
                                    modifyTime: now.adding(.init(.year, -2)).time)
        let last60Days2 = DummyItem(lastUseTime: 0,
                                    modifyTime: now.adding(.init(.day, -40)).time)
        let last60Days3 = DummyItem(lastUseTime: now.adding(.init(.day, -31)).time,
                                    modifyTime: now.adding(.init(.month, -13)).time)

        items.append(contentsOf: [last60Days1, last60Days2, last60Days3])

        // Given last 90 day items
        let last90Days1 = DummyItem(lastUseTime: 0,
                                    modifyTime: now.adding(.init(.day, -78)).time)
        let last90Days2 = DummyItem(lastUseTime: 0,
                                    modifyTime: now.adding(.init(.day, -67)).time)
        let last90Days3 = DummyItem(lastUseTime: now.adding(.init(.day, -61)).time,
                                    modifyTime: now.adding(.init(.year, -7)).time)

        items.append(contentsOf: [last90Days1, last90Days2, last90Days3])

        // Given more than 90 day items
        let moreThan90Days1 = DummyItem(lastUseTime: 0,
                                        modifyTime: now.adding(.init(.year, -2)).time)
        let moreThan90Days2 = DummyItem(lastUseTime: now.adding(.init(.month, -8)).time,
                                        modifyTime: now.adding(.init(.year, -10)).time)
        let moreThan90Days3 = DummyItem(lastUseTime: now.adding(.init(.day, -100)).time,
                                        modifyTime: now.adding(.init(.day, -200)).time)

        items.append(contentsOf: [moreThan90Days1, moreThan90Days2, moreThan90Days3])

        XCTAssertEqual(items.count, 24)

        items.shuffle()

        // When
        let sortedItems = items.mostRecentSortResult()

        // Then
        // Today
        let today = sortedItems.today
        XCTAssertEqual(today.count, 3)
        assertEqual(today[0], today3)
        assertEqual(today[1], today2)
        assertEqual(today[2], today1)

        // Yesterday
        let yesterday = sortedItems.yesterday
        XCTAssertEqual(yesterday.count, 3)
        assertEqual(yesterday[0], yesterday3)
        assertEqual(yesterday[1], yesterday2)
        assertEqual(yesterday[2], yesterday1)

        // Last 7 days
        let last7Days = sortedItems.last7Days
        XCTAssertEqual(last7Days.count, 3)
        assertEqual(last7Days[0], last7Days2)
        assertEqual(last7Days[1], last7Days1)
        assertEqual(last7Days[2], last7Days3)

        // Last 14 days
        let last14Days = sortedItems.last14Days
        XCTAssertEqual(last14Days.count, 3)
        assertEqual(last14Days[0], last14Days2)
        assertEqual(last14Days[1], last14Days1)
        assertEqual(last14Days[2], last14Days3)

        // Last 30 days
        let last30Days = sortedItems.last30Days
        XCTAssertEqual(last30Days.count, 3)
        assertEqual(last30Days[0], last30Days2)
        assertEqual(last30Days[1], last30Days1)
        assertEqual(last30Days[2], last30Days3)

        // Last 60 days
        let last60Days = sortedItems.last60Days
        XCTAssertEqual(last60Days.count, 3)
        assertEqual(last60Days[0], last60Days3)
        assertEqual(last60Days[1], last60Days1)
        assertEqual(last60Days[2], last60Days2)

        // Last 90 days
        let last90Days = sortedItems.last90Days
        XCTAssertEqual(last90Days.count, 3)
        assertEqual(last90Days[0], last90Days3)
        assertEqual(last90Days[1], last90Days2)
        assertEqual(last90Days[2], last90Days1)

        // Others
        let others = sortedItems.others
        XCTAssertEqual(others.count, 3)
        assertEqual(others[0], moreThan90Days3)
        assertEqual(others[1], moreThan90Days2)
        assertEqual(others[2], moreThan90Days1)
    }

    func assertEqual(_ lhs: MostRecentSortable, _ rhs: MostRecentSortable) {
        XCTAssertEqual(lhs.lastUseTime, rhs.lastUseTime)
        XCTAssertEqual(lhs.modifyTime, rhs.modifyTime)
    }
}

private extension Date {
    var time: Int64 { Int64(timeIntervalSince1970) }
}

private struct ComponentValue {
    let component: Calendar.Component
    let value: Int

    init(_ component: Calendar.Component, _ value: Int) {
        self.component = component
        self.value = value
    }
}

private extension Date {
    func adding(_ values: ComponentValue...) -> Date {
        var newDate = self
        values.forEach { value in
            newDate = newDate.adding(component: value.component, value: value.value)
        }
        return newDate
    }
}
