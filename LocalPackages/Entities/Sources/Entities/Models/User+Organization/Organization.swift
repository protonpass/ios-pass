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

    enum ExportMode: Int, Sendable, Decodable, Equatable {
        /// Anyone can export data
        case anyone = 0

        /// Only admins can export data
        case admins = 1

        public static var `default`: Self { .admins }
    }

    struct Settings: Sendable, Decodable, Equatable {
        public let shareMode: ShareMode

        /// 0 means lock time is not enforced
        public let forceLockSeconds: Int

        public let exportMode: ExportMode

        public let passwordPolicy: PasswordPolicy?

        public init(shareMode: ShareMode,
                    forceLockSeconds: Int,
                    exportMode: ExportMode,
                    passwordPolicy: PasswordPolicy?) {
            self.shareMode = shareMode
            self.forceLockSeconds = forceLockSeconds
            self.exportMode = exportMode
            self.passwordPolicy = passwordPolicy
        }
    }
}

public struct PasswordPolicy: Sendable, Codable, Equatable {
    public let randomPasswordAllowed: Bool
    public let randomPasswordMinLength: Int
    public let randomPasswordMaxLength: Int
    public let randomPasswordMustIncludeNumbers: Bool
    public let randomPasswordMustIncludeSymbols: Bool
    public let randomPasswordMustIncludeUppercase: Bool
    public let memorablePasswordAllowed: Bool
    public let memorablePasswordMinWords: Int
    public let memorablePasswordMaxWords: Int
    public let memorablePasswordMustCapitalize: Bool
    public let memorablePasswordMustIncludeNumbers: Bool

    public init(randomPasswordAllowed: Bool,
                randomPasswordMinLength: Int,
                randomPasswordMaxLength: Int,
                randomPasswordMustIncludeNumbers: Bool,
                randomPasswordMustIncludeSymbols: Bool,
                randomPasswordMustIncludeUppercase: Bool,
                memorablePasswordAllowed: Bool,
                memorablePasswordMinWords: Int,
                memorablePasswordMaxWords: Int,
                memorablePasswordMustCapitalize: Bool,
                memorablePasswordMustIncludeNumbers: Bool) {
        self.randomPasswordAllowed = randomPasswordAllowed
        self.randomPasswordMinLength = randomPasswordMinLength
        self.randomPasswordMaxLength = randomPasswordMaxLength
        self.randomPasswordMustIncludeNumbers = randomPasswordMustIncludeNumbers
        self.randomPasswordMustIncludeSymbols = randomPasswordMustIncludeSymbols
        self.randomPasswordMustIncludeUppercase = randomPasswordMustIncludeUppercase
        self.memorablePasswordAllowed = memorablePasswordAllowed
        self.memorablePasswordMinWords = memorablePasswordMinWords
        self.memorablePasswordMaxWords = memorablePasswordMaxWords
        self.memorablePasswordMustCapitalize = memorablePasswordMustCapitalize
        self.memorablePasswordMustIncludeNumbers = memorablePasswordMustIncludeNumbers
    }

    // swiftlint:disable line_length
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        randomPasswordAllowed = try container.decode(Bool.self, forKey: .randomPasswordAllowed)
        randomPasswordMinLength = (try? container.decodeIfPresent(Int.self, forKey: .randomPasswordMinLength)) ?? 4
        randomPasswordMaxLength = (try? container.decodeIfPresent(Int.self, forKey: .randomPasswordMaxLength)) ??
            64
        randomPasswordMustIncludeNumbers = (try? container.decodeIfPresent(Bool.self,
                                                                           forKey: .randomPasswordMustIncludeNumbers)) ??
            true
        randomPasswordMustIncludeSymbols = (try? container.decodeIfPresent(Bool.self,
                                                                           forKey: .randomPasswordMustIncludeSymbols)) ??
            true
        randomPasswordMustIncludeUppercase = (try? container.decodeIfPresent(Bool.self,
                                                                             forKey: .randomPasswordMustIncludeUppercase)) ??
            true
        memorablePasswordAllowed = try container.decode(Bool.self, forKey: .memorablePasswordAllowed)
        memorablePasswordMinWords = (try? container.decodeIfPresent(Int.self,
                                                                    forKey: .memorablePasswordMinWords)) ??
            1
        memorablePasswordMaxWords = (try? container.decodeIfPresent(Int.self,
                                                                    forKey: .memorablePasswordMaxWords)) ??
            10
        memorablePasswordMustCapitalize = (try? container.decodeIfPresent(Bool.self,
                                                                          forKey: .memorablePasswordMustCapitalize)) ??
            true
        memorablePasswordMustIncludeNumbers = (try? container.decodeIfPresent(Bool.self,
                                                                              forKey: .memorablePasswordMustIncludeNumbers)) ??
            true
    }

    // swiftlint:enable line_length

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

    // MARK: Private

    private enum CodingKeys: String, CodingKey {
        case randomPasswordAllowed = "RandomPasswordAllowed"
        case randomPasswordMinLength = "RandomPasswordMinLength"
        case randomPasswordMaxLength = "RandomPasswordMaxLength"
        case randomPasswordMustIncludeNumbers = "RandomPasswordMustIncludeNumbers"
        case randomPasswordMustIncludeSymbols = "RandomPasswordMustIncludeSymbols"
        case randomPasswordMustIncludeUppercase = "RandomPasswordMustIncludeUppercase"
        case memorablePasswordAllowed = "MemorablePasswordAllowed"
        case memorablePasswordMinWords = "MemorablePasswordMinWords"
        case memorablePasswordMaxWords = "MemorablePasswordMaxWords"
        case memorablePasswordMustCapitalize = "MemorablePasswordMustCapitalize"
        case memorablePasswordMustIncludeNumbers = "MemorablePasswordMustIncludeNumbers"
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
