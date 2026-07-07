//
// InMemoryTokenStorage.swift
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

import os
import ProtonCorePayments

extension PaymentToken: @unchecked @retroactive Sendable {}

public final class InMemoryTokenStorage: PaymentTokenStorage, Sendable {
    private let state = OSAllocatedUnfairLock<PaymentToken?>(initialState: nil)

    public init() {}

    public func add(_ token: PaymentToken) {
        state.withLock { $0 = token }
    }

    public func get() -> PaymentToken? {
        state.withLock { $0 }
    }

    public func clear() {
        state.withLock { $0 = nil }
    }
}
