//
// UserSettings.swift
// Proton Pass - Created on 28/05/2023.
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

public struct UserSettings: Sendable {
    public let telemetry: Bool
    public let highSecurity: HighSecurity

    static var `default`: UserSettings {
        UserSettings(telemetry: false, highSecurity: HighSecurity.default)
    }
}

extension UserSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case telemetry
        case highSecurity
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 0 or 1, 1 means sending telemetry enabled
        let telemetry = try container.decode(Int.self, forKey: .telemetry)
        self.telemetry = telemetry >= 1
        highSecurity = try container.decode(HighSecurity.self, forKey: .highSecurity)
    }
}

public struct HighSecurity: Codable, Sendable {
    public let eligible: Bool
    public let active: Bool

    init(eligible: Bool, active: Bool) {
        self.active = active
        self.eligible = eligible
    }

    static var `default`: HighSecurity {
        HighSecurity(eligible: false, active: false)
    }

    enum CodingKeys: String, CodingKey {
        case eligible
        case active = "Value"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 0 or 1, 1 means user is eligible to sentinel
        let eligible = try container.decode(Int.self, forKey: .eligible)
        self.eligible = eligible >= 1
        // 0 or 1, 1 means sentinel is active
        let active = try container.decode(Int.self, forKey: .active)
        self.active = active >= 1
    }
}
