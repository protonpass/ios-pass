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
import Foundation
import ProtonCoreNetworking

public final class LocalUnauthCredentialDatasourceProtocolMock: @unchecked Sendable, LocalUnauthCredentialDatasourceProtocol {

    public init() {}

    // MARK: - getUnauthCredential
    public var getUnauthCredentialThrowableError1: Error?
    public var closureGetUnauthCredential: () -> () = {}
    public var invokedGetUnauthCredentialfunction = false
    public var invokedGetUnauthCredentialCount = 0
    public var stubbedGetUnauthCredentialResult: AuthCredential?

    public func getUnauthCredential() throws -> AuthCredential? {
        invokedGetUnauthCredentialfunction = true
        invokedGetUnauthCredentialCount += 1
        if let error = getUnauthCredentialThrowableError1 {
            throw error
        }
        closureGetUnauthCredential()
        return stubbedGetUnauthCredentialResult
    }
    // MARK: - upsertUnauthCredential
    public var upsertUnauthCredentialThrowableError2: Error?
    public var closureUpsertUnauthCredential: () -> () = {}
    public var invokedUpsertUnauthCredentialfunction = false
    public var invokedUpsertUnauthCredentialCount = 0
    public var invokedUpsertUnauthCredentialParameters: (credential: AuthCredential, Void)?
    public var invokedUpsertUnauthCredentialParametersList = [(credential: AuthCredential, Void)]()

    public func upsertUnauthCredential(_ credential: AuthCredential) throws {
        invokedUpsertUnauthCredentialfunction = true
        invokedUpsertUnauthCredentialCount += 1
        invokedUpsertUnauthCredentialParameters = (credential, ())
        invokedUpsertUnauthCredentialParametersList.append((credential, ()))
        if let error = upsertUnauthCredentialThrowableError2 {
            throw error
        }
        closureUpsertUnauthCredential()
    }
    // MARK: - removeUnauthCredential
    public var removeUnauthCredentialThrowableError3: Error?
    public var closureRemoveUnauthCredential: () -> () = {}
    public var invokedRemoveUnauthCredentialfunction = false
    public var invokedRemoveUnauthCredentialCount = 0

    public func removeUnauthCredential() throws {
        invokedRemoveUnauthCredentialfunction = true
        invokedRemoveUnauthCredentialCount += 1
        if let error = removeUnauthCredentialThrowableError3 {
            throw error
        }
        closureRemoveUnauthCredential()
    }
}
