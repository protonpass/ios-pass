//
// EmailBreaches.swift
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

public struct EmailBreaches: Decodable, Equatable, Sendable, Hashable {
    public let isEligible: Bool
    public let count: Int
    public let breaches: [Breach]

    public init(isEligible: Bool,
                count: Int,
                breaches: [Breach]) {
        self.isEligible = isEligible
        self.count = count
        self.breaches = breaches
    }
}
