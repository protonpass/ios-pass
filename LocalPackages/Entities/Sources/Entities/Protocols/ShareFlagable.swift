//
// ShareFlagable.swift
// Proton Pass - Created on 25/06/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Foundation

public protocol ShareFlagable: Sendable {
    var flags: Int { get }
}

extension ShareFlagable {
    var shareFlags: ShareFlags {
        .init(rawValue: flags)
    }
}

public extension ShareFlagable {
    var hidden: Bool {
        shareFlags.contains(.hidden)
    }
}

public struct ShareFlags: Sendable, OptionSet {
    public var rawValue: Int
    public static let hidden = ShareFlags(rawValue: 1 << 0)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
