//
// Domain.swift
// Proton Pass - Created on 06/08/2024.
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

public struct Domain: Decodable, Hashable, Equatable, Sendable, Identifiable {
    public let domain: String
    public let isCustom: Bool
    public let isPremium: Bool
    public let isDefault: Bool

    public init(domain: String,
                isCustom: Bool,
                isPremium: Bool,
                isDefault: Bool) {
        self.domain = domain
        self.isCustom = isCustom
        self.isPremium = isPremium
        self.isDefault = isDefault
    }

    public var id: String {
        domain
    }
}
