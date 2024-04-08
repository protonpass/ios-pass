//
// KeychainProtocolMockProvider.swift
// Proton Pass - Created on 04/04/2024.
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
//

import Core
import Foundation

public final class KeychainProtocolMockProvider {
    private var data: [String: Data] = [:]
    private var keychain: (any KeychainProtocol)?

    public init() {}
}

public extension KeychainProtocolMockProvider {
    func setUp() {
        let keychain = KeychainProtocolMock()

        keychain.closureSetOrErrorDataKeyAttributes3 = {
            if let data = keychain.invokedSetOrErrorDataKeyAttributesParameters3?.0,
               let key = keychain.invokedSetOrErrorDataKeyAttributesParameters3?.1 {
                self.data[key] = data
            }
        }

        keychain.closureDataOrError = {
            if let key = keychain.invokedDataOrErrorParameters?.0 {
                keychain.stubbedDataOrErrorResult = self.data[key]
            }
        }

        keychain.closureRemoveOrError = {
            if let key = keychain.invokedRemoveOrErrorParameters?.0 {
                self.data[key] = nil
            }
        }
        self.keychain = keychain
    }

    func getKeychain() -> any KeychainProtocol {
        guard let keychain else {
            fatalError("Keychain not initialized")
        }
        return keychain
    }
}
