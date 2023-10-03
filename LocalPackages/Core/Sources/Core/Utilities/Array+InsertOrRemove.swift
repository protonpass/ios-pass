//
// Array+InsertOrRemove.swift
// Proton Pass - Created on 16/02/2023.
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
