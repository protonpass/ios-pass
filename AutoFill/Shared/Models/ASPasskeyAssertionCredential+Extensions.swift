//
// ASPasskeyAssertionCredential+Extensions.swift
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

import AuthenticationServices
import CryptoKit
import Entities

extension ASPasskeyAssertionCredential {
    func setPrfOutput(_ prf: PasskeyPrfValues?) {
        guard #available(iOS 18.0, *), let prf else { return }
        let firstKey = SymmetricKey(data: prf.first)
        let secondKey: SymmetricKey? = prf.second.map { .init(data: $0) }
        let output = ASAuthorizationPublicKeyCredentialPRFAssertionOutput(first: firstKey,
                                                                          second: secondKey)
        extensionOutput = .init(prf: output)
    }
}
