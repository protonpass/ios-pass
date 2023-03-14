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

public enum SortType: CaseIterable {
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

public protocol DateSortable {
    var dateForSorting: Date { get }
}

// MARK: - Most recent
public struct MostRecentSortResult<T: DateSortable> {
    public let today: [T]
    public let yesterday: [T]
    public let last7Days: [T]
    public let last14Days: [T]
    public let last30Days: [T]
    public let last60Days: [T]
    public let last90Days: [T]
    public let others: [T]
}

public extension Array where Element: DateSortable {
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
        let sortedElements = sorted(by: { $0.dateForSorting > $1.dateForSorting })
        for item in sortedElements {
            let numberOfDaysFromNow = calendar.numberOfDaysBetween(now, and: item.dateForSorting)
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

// MARK: - Alphabetical
// swiftlint:disable identifier_name
public enum AlphabetLetter: Int {
    case sharp = 0, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z

    public var character: String {
        switch self {
        case .sharp: return "#"
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .h: return "H"
        case .i: return "I"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .m: return "M"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        }
    }
}
// swiftlint:enable identifier_name

public struct AlphabetBucket<T: AlphabeticalSortable> {
    public let letter: AlphabetLetter
    public let items: [T]
}

public protocol AlphabeticalSortable {
    var alphabeticalSortableString: String { get }
}

public struct AlphabeticalSortResult<T: AlphabeticalSortable> {
    public let buckets: [AlphabetBucket<T>]
}

public extension Array where Element: AlphabeticalSortable {
    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func alphabeticalSortResult() -> AlphabeticalSortResult<Element> {
        let sortedAlphabetically =
        sorted(by: { $0.alphabeticalSortableString < $1.alphabeticalSortableString })

        let dict = Dictionary(grouping: sortedAlphabetically) { element in
            if let firstCharacter = element.alphabeticalSortableString.first {
                return String(firstCharacter).uppercased()
            } else {
                return ""
            }
        }

        var buckets = [AlphabetBucket<Element>]()
        for key in dict.keys {
            guard let elements = dict[key] else { continue }
            let letter: AlphabetLetter
            switch key.uppercased() {
            case "A": letter = .a
            case "B": letter = .b
            case "C": letter = .c
            case "D": letter = .d
            case "E": letter = .e
            case "F": letter = .f
            case "G": letter = .g
            case "H": letter = .h
            case "I": letter = .i
            case "J": letter = .j
            case "K": letter = .k
            case "L": letter = .l
            case "M": letter = .m
            case "N": letter = .n
            case "O": letter = .o
            case "P": letter = .p
            case "Q": letter = .q
            case "R": letter = .r
            case "S": letter = .s
            case "T": letter = .t
            case "U": letter = .u
            case "V": letter = .v
            case "W": letter = .w
            case "X": letter = .x
            case "Y": letter = .y
            case "Z": letter = .z
            default: letter = .sharp
            }
            buckets.append(.init(letter: letter, items: elements))
        }

        buckets = buckets.sorted { $0.letter.rawValue < $1.letter.rawValue }

        return .init(buckets: buckets)
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length
}

// MARK: - Month year
public struct MonthYear: Hashable {
    public let month: Int
    public let year: Int

    public var relativeString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.month = month
        dateComponents.year = year
        return dateFormatter.string(from: Calendar.current.date(from: dateComponents) ?? .now)
    }

    init(date: Date) {
        let components = Calendar.current.dateComponents([.month, .year], from: date)
        self.month = components.month ?? 0
        self.year = components.year ?? 0
    }
}

extension MonthYear: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.month == rhs.month && lhs.year == rhs.year
    }
}

extension MonthYear: Comparable {
    public static func < (lhs: MonthYear, rhs: MonthYear) -> Bool {
        if lhs.year == rhs.year {
            return lhs.month < rhs.month
        }
        return lhs.year < rhs.year
    }
}

public struct MonthYearBucket<T: DateSortable> {
    public let monthYear: MonthYear
    public let items: [T]
}

public struct MonthYearSortResult<T: DateSortable> {
    public let buckets: [MonthYearBucket<T>]
}

public extension Array where Element: DateSortable {
    func monthYearSortResult(direction: SortDirection) -> MonthYearSortResult<Element> {
        let sortedElements: [Element]
        switch direction {
        case .ascending:
            sortedElements = sorted(by: { $0.dateForSorting < $1.dateForSorting })
        case .descending:
            sortedElements = sorted(by: { $0.dateForSorting > $1.dateForSorting })
        }
        let dict = Dictionary(grouping: sortedElements) { element in
            MonthYear(date: element.dateForSorting)
        }

        var buckets = [MonthYearBucket<Element>]()
        for key in dict.keys {
            guard let elements = dict[key] else { continue }
            buckets.append(.init(monthYear: key, items: elements))
        }

        buckets = buckets.sorted(by: { lhs, rhs in
            switch direction {
            case .ascending:
                return lhs.monthYear < rhs.monthYear
            case .descending:
                return lhs.monthYear > rhs.monthYear
            }
        })

        return .init(buckets: buckets)
    }
}
