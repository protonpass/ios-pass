//  
// CompromisedPasswordCheck+Tests.swift
// Proton Pass - Created on 07/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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

extension CompromisedPasswordCheck {
    /// Factory with per-field overrides. Every non-overridden field is random so that
    /// accidental cross-field coupling in the datasource shows up as a test failure.
    static func random(shareId: String = .random(),
                       itemId: String = .random(),
                       passwordHash: String = .random(),
                       prefix: String = String(UUID().uuidString
                           .replacingOccurrences(of: "-", with: "")
                           .prefix(6))
                           .uppercased(),
                       etag: String = .random(),
                       breachCount: Int = .random(in: 0...1_000),
                       checkedAt: Int = .random(in: 1_600_000_000...2_000_000_000)) -> Self {
        .init(shareId: shareId,
              itemId: itemId,
              passwordHash: passwordHash,
              prefix: prefix,
              etag: etag,
              breachCount: breachCount,
              checkedAt: checkedAt)
    }
}
