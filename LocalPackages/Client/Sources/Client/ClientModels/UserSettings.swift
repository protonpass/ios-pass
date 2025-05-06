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
    public var highSecurity: HighSecurity
    public let password: Password
    public let twoFactor: TwoFactor
    public let flags: Flags

    public init(telemetry: Bool,
                highSecurity: HighSecurity,
                password: Password,
                twoFactor: TwoFactor,
                flags: Flags) {
        self.telemetry = telemetry
        self.highSecurity = highSecurity
        self.password = password
        self.twoFactor = twoFactor
        self.flags = flags
    }

    static var `default`: UserSettings {
        UserSettings(telemetry: false,
                     highSecurity: HighSecurity.default,
                     password: .init(mode: .singlePassword),
                     twoFactor: .init(type: .disabled),
                     flags: .init(edmOptOut: .optedIn))
    }

    public struct Password: Sendable, Codable {
        public let mode: PasswordMode

        public enum PasswordMode: Int, Sendable, Codable {
            case singlePassword = 1
            case loginAndMailboxPassword = 2
        }

        enum CodingKeys: String, CodingKey {
            case mode
        }

        public init(mode: PasswordMode) {
            self.mode = mode
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // 1 means single password, 2 means login + mailbox password
            mode = try container.decode(PasswordMode.self, forKey: .mode)
        }
    }

    public struct TwoFactor: Sendable, Codable {
        public let type: TwoFactorType

        public enum TwoFactorType: Int, Sendable, Codable {
            case disabled = 0
            case otp = 1
            case fido2 = 2
            case both = 3
        }

        enum CodingKeys: String, CodingKey {
            case type = "enabled"
        }

        public init(type: TwoFactorType) {
            self.type = type
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            type = try container.decode(TwoFactorType.self, forKey: .type)
        }
    }

    public struct Flags: Sendable, Codable {
        public let edmOptOut: EdmOptOut

        public enum EdmOptOut: Int, Sendable, Codable {
            case optedIn = 0
            case optedOut = 1
        }

        enum CodingKeys: String, CodingKey {
            case edmOptOut
        }

        public init(edmOptOut: EdmOptOut) {
            self.edmOptOut = edmOptOut
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            edmOptOut = try container.decode(EdmOptOut.self, forKey: .edmOptOut)
        }
    }
}

extension UserSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case telemetry
        case highSecurity
        case password
        case twoFactor = "_2FA"
        case flags
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 0 or 1, 1 means sending telemetry enabled
        let telemetry = try container.decode(Int.self, forKey: .telemetry)
        self.telemetry = telemetry.codableBoolValue
        highSecurity = try container.decode(HighSecurity.self, forKey: .highSecurity)
        password = try container.decode(Password.self, forKey: .password)
        twoFactor = try container.decode(TwoFactor.self, forKey: .twoFactor)
        flags = try container.decode(Flags.self, forKey: .flags)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode `telemetry` as 1 if true, else 0
        try container.encode(telemetry.codableIntValue, forKey: .telemetry)

        // Encode `highSecurity` as it is (it handles its own encoding logic)
        try container.encode(highSecurity, forKey: .highSecurity)

        // Encode `password` as it is (it handles its own encoding logic)
        try container.encode(password, forKey: .password)

        // Encode `twoFactorVerify` as it is (it handles its own encoding logic)
        try container.encode(twoFactor, forKey: .twoFactor)

        // Encode `flags` as it is (it handles its own encoding logic)
        try container.encode(flags, forKey: .flags)
    }
}

public struct HighSecurity: Sendable {
    public let eligible: Bool
    public var value: Bool

    public init(eligible: Bool, value: Bool) {
        self.value = value
        self.eligible = eligible
    }

    public static var `default`: HighSecurity {
        HighSecurity(eligible: false, value: false)
    }
}

extension HighSecurity: Codable {
    enum CodingKeys: String, CodingKey {
        case eligible
        case value
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 0 or 1, 1 means user is eligible to sentinel
        let eligible = try container.decode(Int.self, forKey: .eligible)
        self.eligible = eligible.codableBoolValue
        // 0 or 1, 1 means sentinel is active
        let value = try container.decode(Int.self, forKey: .value)
        self.value = value.codableBoolValue
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode `eligible` as 1 if true, else 0
        try container.encode(eligible.codableIntValue, forKey: .eligible)

        // Encode `value` as 1 if true, else 0
        try container.encode(value.codableIntValue, forKey: .value)
    }
}
