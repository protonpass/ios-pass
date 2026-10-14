//
// PasskeyPrf.swift
// Proton Pass - Created on 14/10/2026.
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

public struct PasskeyPrfValues: Sendable, Hashable {
    public let first: Data
    public let second: Data?

    public init(first: Data, second: Data?) {
        self.first = first
        self.second = second
    }
}

public struct PasskeyAssertionPrfInput: Sendable, Hashable {
    public let values: PasskeyPrfValues?
    public let valuesByCredentialId: [Data: PasskeyPrfValues]

    public init(values: PasskeyPrfValues?, valuesByCredentialId: [Data: PasskeyPrfValues]) {
        self.values = values
        self.valuesByCredentialId = valuesByCredentialId
    }

    /// Per-credential values take precedence over the global ones, as mandated by WebAuthn's `evalByCredential`.
    public func values(for credentialId: Data) -> PasskeyPrfValues? {
        valuesByCredentialId[credentialId] ?? values
    }
}
