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

#warning("To be renamed")
public enum SortTypeV2: CaseIterable {
    case mostRecent, alphabetical, newestToNewest, oldestToNewest

    public var title: String {
        switch self {
        case .mostRecent:
            return "Most recent"
        case .alphabetical:
            return "Alphabetical"
        case .newestToNewest:
            return "Newest to oldest"
        case .oldestToNewest:
            return "Oldest to newest"
        }
    }
}

// MARK: - Most recent
public protocol MostRecentSortable {
    var lastUseTime: Int64 { get }
    var modifyTime: Int64 { get }
}

extension MostRecentSortable {
    var greatestTime: Int64 { max(lastUseTime, modifyTime) }
}

public struct MostRecentSortResult<T: MostRecentSortable> {
    public let today: [T]
    public let yesterday: [T]
    public let last7Days: [T]
    public let last14Days: [T]
    public let last30Days: [T]
    public let last60Days: [T]
    public let last90Days: [T]
    public let others: [T]

    public static var empty: MostRecentSortResult {
        .init(today: [],
              yesterday: [],
              last7Days: [],
              last14Days: [],
              last30Days: [],
              last60Days: [],
              last90Days: [],
              others: [])
    }
}

public extension Array where Element: MostRecentSortable {
    func mostRecentSortResult() -> MostRecentSortResult<Element> {
        var today = [Element]()
        var yesterday = [Element]()
        var last7Days = [Element]()
        var last14Days = [Element]()
        var last30Days = [Element]()
        var last60Days = [Element]()
        var last90Days = [Element]()
        var others = [Element]()

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
