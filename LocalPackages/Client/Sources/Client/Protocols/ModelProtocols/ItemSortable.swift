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
import Entities
import Foundation
import Macro

public protocol DateSortable: Hashable, Sendable {
    var dateForSorting: Date { get }
}

// MARK: - Most recent

public struct MostRecentSortResult<T: DateSortable>: SearchResults {
    public var numberOfItems: Int

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

        return MostRecentSortResult(numberOfItems: sortedElements.count,
                                    today: today,
                                    yesterday: yesterday,
                                    last7Days: last7Days,
                                    last14Days: last14Days,
                                    last30Days: last30Days,
                                    last60Days: last60Days,
                                    last90Days: last90Days,
                                    others: others)
    }

    func asyncMostRecentSortResult() async -> MostRecentSortResult<Element> {
        await Task {
            mostRecentSortResult()
        }.value
    }
}

// MARK: - Alphabetical

// swiftlint:disable identifier_name
public enum AlphabetLetter: Int, CaseIterable, Sendable {
    case sharp = 0, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z

    public var character: String {
        switch self {
        case .sharp: "#"
        case .a: "A"
        case .b: "B"
        case .c: "C"
        case .d: "D"
        case .e: "E"
        case .f: "F"
        case .g: "G"
        case .h: "H"
        case .i: "I"
        case .j: "J"
        case .k: "K"
        case .l: "L"
        case .m: "M"
        case .n: "N"
        case .o: "O"
        case .p: "P"
        case .q: "Q"
        case .r: "R"
        case .s: "S"
        case .t: "T"
        case .u: "U"
        case .v: "V"
        case .w: "W"
        case .x: "X"
        case .y: "Y"
        case .z: "Z"
        }
    }

    public static func letters(for direction: SortDirection) -> [AlphabetLetter] {
        switch direction {
        case .ascending:
            allCases
        case .descending:
            allCases.reversed()
        }
    }
}

// swiftlint:enable identifier_name

public struct AlphabetBucket<T: AlphabeticalSortable>: Hashable, Sendable {
    public let letter: AlphabetLetter
    public let items: [T]
}

public protocol AlphabeticalSortable: Hashable, Sendable {
    var alphabeticalSortableString: String { get }
}

public struct AlphabeticalSortResult<T: AlphabeticalSortable>: SearchResults, Sendable {
    public var numberOfItems: Int

    public let buckets: [AlphabetBucket<T>]
}

public extension Array where Element: AlphabeticalSortable {
    // swiftlint:disable cyclomatic_complexity
    func alphabeticalSortResult(direction: SortDirection) -> AlphabeticalSortResult<Element> {
        let dict = Dictionary(grouping: self) { element in
            if let firstCharacter = element.alphabeticalSortableString.first {
                String(firstCharacter).uppercased()
            } else {
                ""
            }
        }

        var buckets = [AlphabetBucket<Element>]()
        var sharpElements = [Element]()
        for key in dict.keys {
            guard let elements = dict[key] else { continue }
            let letter: AlphabetLetter = switch key.uppercased() {
            case "A": .a
            case "B": .b
            case "C": .c
            case "D": .d
            case "E": .e
            case "F": .f
            case "G": .g
            case "H": .h
            case "I": .i
            case "J": .j
            case "K": .k
            case "L": .l
            case "M": .m
            case "N": .n
            case "O": .o
            case "P": .p
            case "Q": .q
            case "R": .r
            case "S": .s
            case "T": .t
            case "U": .u
            case "V": .v
            case "W": .w
            case "X": .x
            case "Y": .y
            case "Z": .z
            default: .sharp
            }

            if letter == .sharp {
                sharpElements.append(contentsOf: elements)
            }

            if letter != .sharp {
                buckets.append(.init(letter: letter, items: elements.sorted(by: direction)))
            }
        }

        buckets.append(.init(letter: .sharp, items: sharpElements.sorted(by: direction)))
        buckets = buckets.sorted { $0.letter.rawValue < $1.letter.rawValue }

        return .init(numberOfItems: count,
                     buckets: direction == .ascending ? buckets : buckets.reversed())
    }

    func asyncAlphabeticalSortResult(direction: SortDirection) async -> AlphabeticalSortResult<Element> {
        await Task {
            alphabeticalSortResult(direction: direction)
        }.value
    }
    // swiftlint:enable cyclomatic_complexity
}

private extension Array where Element: AlphabeticalSortable {
    func sorted(by direction: SortDirection) -> [Element] {
        sorted { lhs, rhs in
            let lString = lhs.alphabeticalSortableString
            let rString = rhs.alphabeticalSortableString
            let result = lString.caseInsensitiveCompare(rString)
            return switch direction {
            case .ascending:
                result == .orderedAscending
            case .descending:
                result == .orderedDescending
            }
        }
    }
}

// MARK: - Month year

public struct MonthYear: Hashable, Sendable {
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
        month = components.month ?? 0
        year = components.year ?? 0
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

public struct MonthYearBucket<T: DateSortable>: Hashable, Sendable {
    public let monthYear: MonthYear
    public let items: [T]
}

public struct MonthYearSortResult<T: DateSortable>: SearchResults {
    public var numberOfItems: Int

    public let buckets: [MonthYearBucket<T>]
}

public extension Array where Element: DateSortable {
    func monthYearSortResult(direction: SortDirection) -> MonthYearSortResult<Element> {
        let sortedElements: [Element] = switch direction {
        case .ascending:
            sorted(by: { $0.dateForSorting < $1.dateForSorting })
        case .descending:
            sorted(by: { $0.dateForSorting > $1.dateForSorting })
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
                lhs.monthYear < rhs.monthYear
            case .descending:
                lhs.monthYear > rhs.monthYear
            }
        })

        return .init(numberOfItems: sortedElements.count, buckets: buckets)
    }

    func asyncMonthYearSortResult(direction: SortDirection) async -> MonthYearSortResult<Element> {
        await Task {
            monthYearSortResult(direction: direction)
        }.value
    }
}

public protocol SearchResults: Hashable, Equatable, Sendable {
    var numberOfItems: Int { get }
}
