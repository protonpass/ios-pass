//
// UpdateMonitorStateRequest.swift
// Proton Pass - Created on 22/04/2024.
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
//

import Foundation

public enum UpdateMonitorStateRequest: Sendable, Encodable {
    case protonAddress(Bool)
    case aliases(Bool)

    enum CodingKeys: String, CodingKey {
        case protonAddress = "ProtonAddress"
        case aliases = "Aliases"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .protonAddress(monitored):
            try container.encode(monitored, forKey: .protonAddress)
        case let .aliases(monitored):
            try container.encode(monitored, forKey: .aliases)
        }
    }
}
