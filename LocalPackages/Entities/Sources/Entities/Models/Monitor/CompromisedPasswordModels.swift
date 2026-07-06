//
// CompromisedPasswordModels.swift
// Proton Pass - Created on 18/06/2026.
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

import Foundation

/// A login item to check against the compromised-password (k-anonymity) corpus.
public struct CompromisedPasswordCandidate: Sendable, Equatable {
    public let shareId: String
    public let itemId: String
    /// The exact stored password. Hashed verbatim (no trimming/normalization).
    public let password: String

    public init(shareId: String, itemId: String, password: String) {
        self.shareId = shareId
        self.itemId = itemId
        self.password = password
    }
}

/// Per-item compromised-password state persisted locally to honour the corpus's
/// `last_change` freshness and `ETag` conditional-request model. Scoped to a user by the
/// datasource (the user id is not carried on the value, mirroring `ItemReadEvent`).
public struct CompromisedPasswordCheck: Sendable, Equatable {
    public let shareId: String
    public let itemId: String
    /// SHA-256 hex of the exact stored password — the password-change invalidation key.
    public let passwordHash: String
    /// Uppercase SHA-1 hex prefix (first 6 chars) the stored `etag`/result belong to.
    public let prefix: String
    /// ETag from the most recent successful range query for this item's prefix (empty when none).
    public let etag: String
    public let breachCount: Int
    /// UNIX epoch seconds of the most recent successful range query.
    public let checkedAt: Int

    public var id: String {
        itemId + shareId
    }

    public init(shareId: String,
                itemId: String,
                passwordHash: String,
                prefix: String,
                etag: String,
                breachCount: Int,
                checkedAt: Int) {
        self.shareId = shareId
        self.itemId = itemId
        self.passwordHash = passwordHash
        self.prefix = prefix
        self.etag = etag
        self.breachCount = breachCount
        self.checkedAt = checkedAt
    }
}

/// Result of a conditional range query against the compromised-password service.
public enum CompromisedRangeResponse: Sendable {
    /// HTTP 304 — the range slice has not changed; the caller must reuse its cached result.
    case notModified
    /// HTTP 200 — gunzipped body of `SUFFIX:COUNT` lines, plus the response `ETag` (if any).
    case modified(etag: String?, body: Data)
}
