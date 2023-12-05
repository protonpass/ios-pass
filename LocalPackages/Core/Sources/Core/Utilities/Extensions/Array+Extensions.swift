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

public extension ArraySlice {
    var toArray: [Element] {
        Array(self)
    }
}

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
}
