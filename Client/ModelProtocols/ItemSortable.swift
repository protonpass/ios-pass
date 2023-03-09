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
        let sortedByTime = sorted(by: { $0.dateForSorting > $1.dateForSorting })
        for item in sortedByTime {
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
public enum AlphabetLetter {
    case sharp, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z

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
        var buckets = [AlphabetBucket<Element>]()

        let sortedAlphabetically =
        sorted(by: { $0.alphabeticalSortableString < $1.alphabeticalSortableString })

        var sharpItems = [Element](), aItems = [Element](), bItems = [Element]()
        var cItems = [Element](), dItems = [Element](), eItems = [Element]()
        var fItems = [Element](), gItems = [Element](), hItems = [Element]()
        var iItems = [Element](), jItems = [Element](), kItems = [Element]()
        var lItems = [Element](), mItems = [Element](), nItems = [Element]()
        var oItems = [Element](), pItems = [Element](), qItems = [Element]()
        var rItems = [Element](), sItems = [Element](), tItems = [Element]()
        var uItems = [Element](), vItems = [Element](), wItems = [Element]()
        var xItems = [Element](), yItems = [Element](), zItems = [Element]()

        for item in sortedAlphabetically {
            if let firstCharacter = item.alphabeticalSortableString.first {
                switch String(firstCharacter).uppercased() {
                case "A": aItems.append(item)
                case "B": bItems.append(item)
                case "C": cItems.append(item)
                case "D": dItems.append(item)
                case "E": eItems.append(item)
                case "F": fItems.append(item)
                case "G": gItems.append(item)
                case "H": hItems.append(item)
                case "I": iItems.append(item)
                case "J": jItems.append(item)
                case "K": kItems.append(item)
                case "L": lItems.append(item)
                case "M": mItems.append(item)
                case "N": nItems.append(item)
                case "O": oItems.append(item)
                case "P": pItems.append(item)
                case "Q": qItems.append(item)
                case "R": rItems.append(item)
                case "S": sItems.append(item)
                case "T": tItems.append(item)
                case "U": uItems.append(item)
                case "V": vItems.append(item)
                case "W": wItems.append(item)
                case "X": xItems.append(item)
                case "Y": yItems.append(item)
                case "Z": zItems.append(item)
                default: sharpItems.append(item)
                }
            } else {
                sharpItems.append(item)
            }
        }

        if !sharpItems.isEmpty { buckets.append(.init(letter: .sharp, items: sharpItems)) }
        if !aItems.isEmpty { buckets.append(.init(letter: .a, items: aItems)) }
        if !bItems.isEmpty { buckets.append(.init(letter: .b, items: bItems)) }
        if !cItems.isEmpty { buckets.append(.init(letter: .c, items: cItems)) }
        if !dItems.isEmpty { buckets.append(.init(letter: .d, items: dItems)) }
        if !eItems.isEmpty { buckets.append(.init(letter: .e, items: eItems)) }
        if !fItems.isEmpty { buckets.append(.init(letter: .f, items: fItems)) }
        if !gItems.isEmpty { buckets.append(.init(letter: .g, items: gItems)) }
        if !hItems.isEmpty { buckets.append(.init(letter: .h, items: hItems)) }
        if !iItems.isEmpty { buckets.append(.init(letter: .i, items: iItems)) }
        if !jItems.isEmpty { buckets.append(.init(letter: .j, items: jItems)) }
        if !kItems.isEmpty { buckets.append(.init(letter: .k, items: kItems)) }
        if !lItems.isEmpty { buckets.append(.init(letter: .l, items: lItems)) }
        if !mItems.isEmpty { buckets.append(.init(letter: .m, items: mItems)) }
        if !nItems.isEmpty { buckets.append(.init(letter: .n, items: nItems)) }
        if !oItems.isEmpty { buckets.append(.init(letter: .o, items: oItems)) }
        if !pItems.isEmpty { buckets.append(.init(letter: .p, items: pItems)) }
        if !qItems.isEmpty { buckets.append(.init(letter: .q, items: qItems)) }
        if !rItems.isEmpty { buckets.append(.init(letter: .r, items: rItems)) }
        if !sItems.isEmpty { buckets.append(.init(letter: .s, items: sItems)) }
        if !tItems.isEmpty { buckets.append(.init(letter: .t, items: tItems)) }
        if !uItems.isEmpty { buckets.append(.init(letter: .u, items: uItems)) }
        if !vItems.isEmpty { buckets.append(.init(letter: .v, items: vItems)) }
        if !wItems.isEmpty { buckets.append(.init(letter: .w, items: wItems)) }
        if !xItems.isEmpty { buckets.append(.init(letter: .x, items: xItems)) }
        if !yItems.isEmpty { buckets.append(.init(letter: .y, items: yItems)) }
        if !zItems.isEmpty { buckets.append(.init(letter: .z, items: zItems)) }

        return .init(buckets: buckets)
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length
}
