//
// ItemFlags.swift
// Proton Pass - Created on 19/06/2026.
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

public enum ItemFlag: Sendable, Hashable {
    case skipHealthCheck(Bool)
    case skipWeakPasswordCheck(Bool)
    case skipCompromisedPasswordCheck(Bool)
    case skipReusedPasswordCheck(Bool)
    case skip2FACheck(Bool)
}

public extension ItemFlag {
    static func skip(_ kind: WeaknessKind, _ skipped: Bool) -> ItemFlag {
        switch kind {
        case .weakPassword:
            .skipWeakPasswordCheck(skipped)

        case .compromisedPassword:
            .skipCompromisedPasswordCheck(skipped)

        case .reusedPassword:
            .skipReusedPasswordCheck(skipped)

        case .missing2FA:
            .skip2FACheck(skipped)
        }
    }
}
