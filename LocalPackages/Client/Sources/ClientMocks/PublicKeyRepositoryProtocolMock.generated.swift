// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
// Copyright (c) 2023 Proton Technologies AG
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

import Client
import Core
import Entities

public final class PublicKeyRepositoryProtocolMock: @unchecked Sendable, PublicKeyRepositoryProtocol {

    public init() {}

    // MARK: - getPublicKeys
    public var getPublicKeysEmailThrowableError1: Error?
    public var closureGetPublicKeys: () -> () = {}
    public var invokedGetPublicKeysfunction = false
    public var invokedGetPublicKeysCount = 0
    public var invokedGetPublicKeysParameters: (email: String, Void)?
    public var invokedGetPublicKeysParametersList = [(email: String, Void)]()
    public var stubbedGetPublicKeysResult: [PublicKey]!

    public func getPublicKeys(email: String) async throws -> [PublicKey] {
        invokedGetPublicKeysfunction = true
        invokedGetPublicKeysCount += 1
        invokedGetPublicKeysParameters = (email, ())
        invokedGetPublicKeysParametersList.append((email, ()))
        if let error = getPublicKeysEmailThrowableError1 {
            throw error
        }
        closureGetPublicKeys()
        return stubbedGetPublicKeysResult
    }
}
