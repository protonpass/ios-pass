//
// Error+Extensions.swift
// Proton Pass - Created on 14/11/2023.
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
//

import Entities
import Foundation

public extension Error {
    /// Concatenate `localizedDescription` & `debugDescription`
    var localizedDebugDescription: String {
        if let debug = self as? CustomDebugStringConvertible,
           debug.debugDescription != localizedDescription {
            "\(localizedDescription) \(debug.debugDescription)"
        } else {
            localizedDescription
        }
    }

    /// Inactive user key due to password reset, we couldn't do anything but only log it
    var isInactiveUserKey: Bool {
        if let passError = self as? PassError,
           case let .crypto(reason) = passError,
           case .inactiveUserKey = reason {
            true
        } else {
            false
        }
    }
}
