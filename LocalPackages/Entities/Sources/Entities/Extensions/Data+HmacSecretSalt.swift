//
// Data+HmacSecretSalt.swift
// Proton Pass - Created on 21/10/2026.
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

import CryptoKit
import Foundation

public extension Data {
    /// The PRF `eval` value turned into a 32-byte hmac-secret salt, as defined by WebAuthn.
    ///
    /// The system is expected to hash eval values before passing them to the credential provider,
    /// but the request carries nothing that confirms it. Values that are exactly 32 bytes are
    /// therefore assumed to be hashed and returned unchanged; any other length is hashed here.
    /// Known-wrong case: a raw 32-byte eval that the system did not hash is used as-is.
    var hmacSecretSalt: Data {
        guard count != 32 else { return self }
        // https://www.w3.org/TR/webauthn-3/#prf-extension
        let input = Data("WebAuthn PRF".utf8) + [0x00] + self
        return Data(SHA256.hash(data: input))
    }
}
