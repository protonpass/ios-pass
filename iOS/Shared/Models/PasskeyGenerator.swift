//
// PasskeyGenerator.swift
// Proton Pass - Created on 27/02/2024.
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

import Entities
import UseCases

/// Stores the request and caches the generated passkey
/// to make sure we only generate one passkey for a given request
final class PasskeyGenerator {
    let request: PasskeyCredentialRequest
    private var passkey: CreatePasskeyResponse?

    init(request: PasskeyCredentialRequest) {
        self.request = request
    }

    func getPasskey(createPasskey: any CreatePasskeyUseCase) throws -> CreatePasskeyResponse {
        if let passkey {
            return passkey
        }
        let passkey = try createPasskey(request)
        self.passkey = passkey
        return passkey
    }
}
