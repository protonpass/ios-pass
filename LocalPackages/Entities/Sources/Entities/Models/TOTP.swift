//
// TOTP.swift
// Proton Pass - Created on 20/07/2023.
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

public enum TOTPState: Equatable {
    case loading
    case empty
    case valid(TOTPData)
    case invalid
}

public struct TOTPTimerData: Hashable {
    public let total: Int
    public let remaining: Int

    public init(total: Int, remaining: Int) {
        self.total = total
        self.remaining = remaining
    }
}

public struct TOTPData: Equatable {
    public let code: String
    public let timerData: TOTPTimerData

    public init(code: String, timerData: TOTPTimerData) {
        self.code = code
        self.timerData = timerData
    }
}
