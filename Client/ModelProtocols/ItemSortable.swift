//
// ItemSortable.swift
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

import Core

/// Should be conformed by structs that represent items with dates.
/// So that they can be sorted for the homepage.
public protocol ItemSortable {
    var lastUseTime: Int64 { get }
    var modifyTime: Int64 { get }
}

extension ItemSortable {
    var greatestTime: Int64 { max(lastUseTime, modifyTime) }
}

public struct SortedItems {
    public let today: [ItemSortable]
    public let yesterday: [ItemSortable]
    public let last7Days: [ItemSortable]
    public let last14Days: [ItemSortable]
    public let last30Days: [ItemSortable]
    public let last60Days: [ItemSortable]
    public let last90Days: [ItemSortable]
    public let others: [ItemSortable]
}

extension Array where Element == ItemSortable {
    func sortedItems() -> SortedItems {
        var today = [ItemSortable]()
        var yesterday = [ItemSortable]()
        var last7Days = [ItemSortable]()
        var last14Days = [ItemSortable]()
        var last30Days = [ItemSortable]()
        var last60Days = [ItemSortable]()
        var last90Days = [ItemSortable]()
        var others = [ItemSortable]()

        let calendar = Calendar.current
        let now = Date()
        let sortedByTime = sorted(by: { $0.greatestTime > $1.greatestTime })
        for item in sortedByTime {
            let itemDate = Date(timeIntervalSince1970: TimeInterval(item.greatestTime))
            let numberOfDaysFromNow = calendar.numberOfDaysBetween(now, and: itemDate)
            switch abs(numberOfDaysFromNow) {
            case 0:
                today.append(item)
            case 1:
                yesterday.append(item)
            case 2..<7:
                last7Days.append(item)
            case 7..<14:
                last14Days.append(item)
            case 14..<30:
                last30Days.append(item)
            case 30..<60:
                last60Days.append(item)
            case 60..<90:
                last90Days.append(item)
            default:
                others.append(item)
            }
        }

        return .init(today: today,
                     yesterday: yesterday,
                     last7Days: last7Days,
                     last14Days: last14Days,
                     last30Days: last30Days,
                     last60Days: last60Days,
                     last90Days: last90Days,
                     others: others)
    }
}
