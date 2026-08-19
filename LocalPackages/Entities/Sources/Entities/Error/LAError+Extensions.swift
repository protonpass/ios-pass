//
// LAError+Extensions.swift
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

import LocalAuthentication

public extension LAError {
    /// `true` when the biometric sheet was never shown, or was dismissed without the user's
    /// face/finger ever being judged. Notably `notInteractive` (-1004, "Caller is not running
    /// foreground"), raised when we prompt before the app or extension is frontmost.
    ///
    /// None of these is a wrong face, so none may consume an unlock attempt: 3 consumed attempts
    /// revoke the session and log the user out.
    var reachedNoVerdict: Bool {
        switch code {
        case .appCancel,
             .notInteractive,
             .systemCancel,
             .userCancel,
             .userFallback:
            true

        default:
            false
        }
    }
}
