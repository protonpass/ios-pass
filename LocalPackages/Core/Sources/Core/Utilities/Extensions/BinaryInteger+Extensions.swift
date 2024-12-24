//
// BinaryInteger+Extensions.swift
// Proton Pass - Created on 19/12/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities
import Foundation

public extension BinaryInteger {
    /// For multipart requests, we need to pass integers as byte array
    var toAsciiData: Data {
        var data = Data()
        for char in String(self) {
            if let value = char.asciiValue {
                data.append(value)
            } else {
                // Should never happen as we're looping through each digit of a number
                // Digits are always between 0-9 so ASCII value is always available
                assertionFailure("Should always have ASCII value")
            }
        }
        return data
    }
}
