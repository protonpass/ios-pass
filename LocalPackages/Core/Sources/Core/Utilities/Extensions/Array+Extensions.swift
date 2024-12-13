//
// Array+Extensions.swift
// Proton Pass - Created on 03/07/2023.
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

import Foundation

public extension Array where Element: Identifiable, Element: Equatable {
    /// Compare 2 arrays of `Identifiable` & `Equatable` objects
    /// Return `true` if the 2 arrays contain the same set of objects regardless of their order
    /// Return `false` otherwise
    func isLooselyEqual(to anotherArray: [Element]) -> Bool {
        guard Set(map(\.id)) == Set(anotherArray.map(\.id)) else {
            return false
        }

        for element in self {
            if let anotherElement = anotherArray.first(where: { $0.id == element.id }) {
                if element != anotherElement {
                    return false
                }
            } else {
                return false
            }
        }

        return true
    }
}

public extension Array {
    func groupAndBulkAction<T: Hashable>(by keyPath: KeyPath<Element, T>,
                                         shouldInclude: (Element) -> Bool,
                                         action: ([Element], T) async throws -> Void) async throws {
        let groupedElements = Dictionary(grouping: self) { element in
            element[keyPath: keyPath]
        }

        for (key, subElements) in groupedElements {
            let matchedElements = subElements.filter(shouldInclude)
            if !matchedElements.isEmpty {
                try await action(matchedElements, key)
            }
        }
    }

    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }

    /// Remove duplicated elements with a custom logic to determine the equalness
    func deduplicate<Key: Hashable>(by key: (Element) throws -> Key) rethrows -> [Element] {
        var seenKeys = Set<Key>()
        var result = [Element]()
        for item in self {
            let key = try key(item)
            if !seenKeys.contains(key) {
                result.append(item)
                seenKeys.insert(key)
            }
        }
        return result
    }

    mutating func popAndRemoveFirstElements(_ count: Int) -> [Element] {
        let elements = prefix(count)
        removeFirst(count)
        return Array(elements)
    }
}

public extension Array where Element: Equatable {
    /// Insert if not exist, remove if exist. This method is designed for arrays with unique elements only.
    /// So be careful when using on an array of repeated elements, it will result in undefined behaviors.
    /// - Parameters:
    ///  - element: New element to insert or remove.
    ///  - minItemCount: Minimum number of item that the array must have after removing an element.
    ///  Use to make sure array always  has at least a certain number of items.
    mutating func insertOrRemove(_ element: Element, minItemCount: UInt = 0) {
        if contains(element) {
            if count - 1 >= minItemCount {
                removeAll { $0 == element }
            }
        } else {
            append(element)
        }
    }
}

public extension Array {
    /// CompactMap with set trnasformation.
    /// - Parameter transform: The transform to apply to each element.
    func compactMapToSet<T>(_ transform: (Element) throws -> T?) rethrows -> Set<T> {
        var tempSet = Set<T>()

        for item in self {
            if let element = try transform(item) {
                tempSet.insert(element)
            }
        }

        return tempSet
    }
}
