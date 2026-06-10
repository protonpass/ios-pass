//
// SecurityWeakness.swift
// Proton Pass - Created on 08/03/2024.
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

// swiftlint:disable:next todo
// TODO: Add compromized passwords
public enum SecurityWeakness: Equatable, Sendable, Hashable, Identifiable {
    case weakPasswords(isExcluded: Bool)
    case reusedPasswords(isExcluded: Bool)
    case breaches
    case missing2FA(isExcluded: Bool)
    case fullyExcluded
//    case fullyExcludedItem
//    case excludedWeakPasswords
//    case excludedReusedPasswords
//    case excludedMissing2FA

//    public enum ExclusionType: Equatable, Sendable, Hashable, Identifiable, CaseIterable {
//        case fullItem
//        case weak
//        case reused
//        case twoFA
//
//        public var id: Self {
//            self
//        }
//    }

    public var id: Self {
        self
    }

    public var isExcluded: Bool {
        switch self {
        case let .missing2FA(isExcluded: isExcluded),
             let .reusedPasswords(isExcluded: isExcluded),
             let .weakPasswords(isExcluded: isExcluded):
            isExcluded

        case .fullyExcluded:
            true

        default:
            false
        }
    }

    public var hasReusedPasswords: Bool {
        guard case .reusedPasswords = self else { return false }
        return true
    }

//    public var exclusionType: ExclusionType? {
//        guard case let .excluded(type) = self else { return nil }
//        return type
//    }
//
//    public static var allExclusions: [SecurityWeakness] {
//        ExclusionType.allCases.map { .excluded($0) }
//    }
}

public extension [SecurityWeakness] {
    var containsExcluded: Bool {
        contains(where: \.isExcluded)
    }

    var containsReused: Bool {
        contains(where: \.hasReusedPasswords)
    }
}
