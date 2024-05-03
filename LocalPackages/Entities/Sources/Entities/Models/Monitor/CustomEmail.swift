//
// CustomEmail.swift
// Proton Pass - Created on 10/04/2024.
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

import Foundation

public struct CustomEmail: Decodable, Equatable, Sendable, Hashable, Identifiable {
    public let customEmailID, email: String
    public let verified: Bool
    public let breachCounter: Int
    public let flags: Int
    public let lastBreachTime: Int?

    public init(customEmailID: String,
                email: String,
                verified: Bool,
                breachCounter: Int,
                flags: Int,
                lastBreachTime: Int?) {
        self.customEmailID = customEmailID
        self.email = email
        self.verified = verified
        self.breachCounter = breachCounter
        self.flags = flags
        self.lastBreachTime = lastBreachTime
    }

    public var id: String {
        customEmailID
    }
}

extension CustomEmail: Breachable, AddressFlagable {}
