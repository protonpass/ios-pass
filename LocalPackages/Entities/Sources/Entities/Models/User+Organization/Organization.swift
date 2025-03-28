//
// Organization.swift
// Proton Pass - Created on 07/03/2024.
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

public struct Organization: Sendable, Decodable, Equatable {
    /// Whether this user can update the organization
    public let canUpdate: Bool
    public let settings: Settings?

    public init(canUpdate: Bool, settings: Settings?) {
        self.canUpdate = canUpdate
        self.settings = settings
    }
}

public extension Organization {
    enum ShareMode: Int, Sendable, Decodable, Equatable {
        /// Able to share within and outside of organization
        case unrestricted = 0

        /// Only share within organization
        case restricted = 1

        public static var `default`: Self { .restricted }
    }

    enum ItemShareMode: Int, Sendable, Decodable, Equatable {
        case disabled = 0
        case enabled = 1

        public static var `default`: Self { .enabled }
    }

    enum PublicLinkMode: Int, Sendable, Decodable, Equatable {
        case disabled = 0
        case enabled = 1

        public static var `default`: Self { .enabled }
    }

    enum ExportMode: Int, Sendable, Decodable, Equatable {
        /// Anyone can export data
        case anyone = 0

        /// Only admins can export data
        case admins = 1

        public static var `default`: Self { .admins }
    }

    enum VaultCreateMode: Int, Sendable, Decodable, Equatable {
        case anyUser = 0
        case adminsOnly = 1
    }

    struct Settings: Sendable, Decodable, Equatable {
        public let shareMode: ShareMode

        public let itemShareMode: ItemShareMode

        public let publicLinkMode: PublicLinkMode

        /// 0 means lock time is not enforced
        public let forceLockSeconds: Int

        public let exportMode: ExportMode

        public let passwordPolicy: PasswordPolicy?

        public let vaultCreateMode: VaultCreateMode?

        public init(shareMode: ShareMode,
                    itemShareMode: ItemShareMode,
                    publicLinkMode: PublicLinkMode,
                    forceLockSeconds: Int,
                    exportMode: ExportMode,
                    passwordPolicy: PasswordPolicy?,
                    vaultCreateMode: VaultCreateMode?) {
            self.shareMode = shareMode
            self.itemShareMode = itemShareMode
            self.publicLinkMode = publicLinkMode
            self.forceLockSeconds = forceLockSeconds
            self.exportMode = exportMode
            self.passwordPolicy = passwordPolicy
            self.vaultCreateMode = vaultCreateMode
        }
    }
}

//
// RandomPasswordAllowed
// required
// boolean
// Whether subusers are allowed to generate random passwords
//
// RandomPasswordMinLength
// integer or null >= 4
// Minimum password length. Default limit if null.
//
// RandomPasswordMaxLength
// integer or null <= 64
// Maximum password length. Default limit if null.
//
// RandomPasswordMustIncludeNumbers
// boolean or null
// Whether the password must include numbers. If true, it must. If false, it must not. Cannot be changed if not
// null. Can be changed if null.
//
// RandomPasswordMustIncludeSymbols
// boolean or null
// Whether the password must include symbols. If true, it must. If false, it must not. Cannot be changed if not
// null. Can be changed if null.
//
// RandomPasswordMustIncludeUppercase
// boolean or null
// Whether the password must include uppercase characters. If true, it must. If false, it must not. Cannot be
// changed if not null. Can be changed if null.
//
// MemorablePasswordAllowed
// required
// boolean
// Whether subusers are allowed to generate memorable passwords
//
// MemorablePasswordMinWords
// integer or null
// Minimum amount of words for the memorable passwords. Default limit if null.
//
// MemorablePasswordMaxWords
// integer or null
// Maximum amount of words for the memorable passwords. Default limit if null.
//
// MemorablePasswordMustCapitalize
// boolean or null
// Whether the password must capitalize words. If true, it must. If false, it must not. Cannot be changed if not
// null. Can be changed if null.
//
// MemorablePasswordMustIncludeNumbers
// boolean or null
// Whether the password must include numbers. If true, it must. If false, it must not. Cannot be changed if not
// null. Can be changed if null.

// swiftlint:disable discouraged_optional_boolean
public struct PasswordPolicy: Sendable, Codable, Equatable {
    public let randomPasswordAllowed: Bool
    public let randomPasswordMinLength: Int
    public let randomPasswordMaxLength: Int
    public let randomPasswordMustIncludeNumbers: Bool?
    public let randomPasswordMustIncludeSymbols: Bool?
    public let randomPasswordMustIncludeUppercase: Bool?
    public let memorablePasswordAllowed: Bool
    public let memorablePasswordMinWords: Int
    public let memorablePasswordMaxWords: Int
    public let memorablePasswordMustCapitalize: Bool?
    public let memorablePasswordMustIncludeNumbers: Bool?

    public init(randomPasswordAllowed: Bool,
                randomPasswordMinLength: Int?,
                randomPasswordMaxLength: Int?,
                randomPasswordMustIncludeNumbers: Bool?,
                randomPasswordMustIncludeSymbols: Bool?,
                randomPasswordMustIncludeUppercase: Bool?,
                memorablePasswordAllowed: Bool,
                memorablePasswordMinWords: Int?,
                memorablePasswordMaxWords: Int?,
                memorablePasswordMustCapitalize: Bool?,
                memorablePasswordMustIncludeNumbers: Bool?) {
        self.randomPasswordAllowed = randomPasswordAllowed
        self.randomPasswordMinLength = randomPasswordMinLength ?? 4
        self.randomPasswordMaxLength = randomPasswordMaxLength ?? 64
        self.randomPasswordMustIncludeNumbers = randomPasswordMustIncludeNumbers
        self.randomPasswordMustIncludeSymbols = randomPasswordMustIncludeSymbols
        self.randomPasswordMustIncludeUppercase = randomPasswordMustIncludeUppercase
        self.memorablePasswordAllowed = memorablePasswordAllowed
        self.memorablePasswordMinWords = memorablePasswordMinWords ?? 1
        self.memorablePasswordMaxWords = memorablePasswordMaxWords ?? 10
        self.memorablePasswordMustCapitalize = memorablePasswordMustCapitalize
        self.memorablePasswordMustIncludeNumbers = memorablePasswordMustIncludeNumbers
    }

    public static var `default`: PasswordPolicy {
        PasswordPolicy(randomPasswordAllowed: true,
                       randomPasswordMinLength: 4,
                       randomPasswordMaxLength: 64,
                       randomPasswordMustIncludeNumbers: true,
                       randomPasswordMustIncludeSymbols: true,
                       randomPasswordMustIncludeUppercase: true,
                       memorablePasswordAllowed: true,
                       memorablePasswordMinWords: 1,
                       memorablePasswordMaxWords: 10,
                       memorablePasswordMustCapitalize: true,
                       memorablePasswordMustIncludeNumbers: true)
    }
}

public extension PasswordPolicy {
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode(PasswordPolicy.self, from: data)
        else {
            return nil
        }
        self = result
    }
}

public extension Organization.Settings {
    /// `AppLockTime` base on `forceLockSeconds`
    /// Return `nil` if not applicable
    var appLockTime: AppLockTime? {
        switch forceLockSeconds {
        case 0:
            nil
        case 1...60:
            .oneMinute
        case 61...120:
            .twoMinutes
        case 121...300:
            .fiveMinutes
        case 301...600:
            .tenMinutes
        case 601...3_600:
            .oneHour
        default:
            .fourHours
        }
    }
}

// swiftlint:enable discouraged_optional_boolean
