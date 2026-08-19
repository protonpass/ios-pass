//
// LocalAuthenticationState.swift
// Proton Pass - Created on 18/08/2026.
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

public enum LocalAuthenticationState: Equatable, Sendable {
    case noAttempts
    case remainingAttempts(Int)
    case lastAttempt

    /// No attempt left. The caller is expected to log the user out.
    case exhausted

    public init(failedAttemptCount: Int, maxAttemptCount: Int) {
        switch failedAttemptCount {
        case 0:
            self = .noAttempts

        case maxAttemptCount - 1:
            self = .lastAttempt

        default:
            let remainingAttempts = maxAttemptCount - failedAttemptCount
            self = remainingAttempts >= 1 ? .remainingAttempts(remainingAttempts) : .exhausted
        }
    }
}
