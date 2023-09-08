//
// AliasOptions.swift
// Proton Pass - Created on 14/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public struct AliasOptions: Decodable, Sendable {
    public let suffixes: [Suffix]
    public let mailboxes: [Mailbox]
    public let canCreateAlias: Bool
}

public struct Suffix: Decodable, Hashable, Sendable {
    public let suffix: String
    public let domain: String
    public let signedSuffix: String
    public let isCustom: Bool

    public init(suffix: String, domain: String, signedSuffix: String, isCustom: Bool) {
        self.suffix = suffix
        self.domain = domain
        self.signedSuffix = signedSuffix
        self.isCustom = isCustom
    }
}

extension Suffix: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.suffix == rhs.suffix &&
            lhs.domain == rhs.domain &&
            lhs.signedSuffix == rhs.signedSuffix &&
            lhs.isCustom == rhs.isCustom
    }
}
