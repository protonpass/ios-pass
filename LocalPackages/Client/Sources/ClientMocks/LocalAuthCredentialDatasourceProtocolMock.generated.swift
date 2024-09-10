// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
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
import CoreData
import CryptoKit
import Entities
import Foundation
import ProtonCoreNetworking

public final class LocalAuthCredentialDatasourceProtocolMock: @unchecked Sendable, LocalAuthCredentialDatasourceProtocol {

    public init() {}

    // MARK: - getCredential
    public var getCredentialUserIdModuleThrowableError1: Error?
    public var closureGetCredential: () -> () = {}
    public var invokedGetCredentialfunction = false
    public var invokedGetCredentialCount = 0
    public var invokedGetCredentialParameters: (userId: String, module: PassModule)?
    public var invokedGetCredentialParametersList = [(userId: String, module: PassModule)]()
    public var stubbedGetCredentialResult: AuthCredential?

    public func getCredential(userId: String, module: PassModule) async throws -> AuthCredential? {
        invokedGetCredentialfunction = true
        invokedGetCredentialCount += 1
        invokedGetCredentialParameters = (userId, module)
        invokedGetCredentialParametersList.append((userId, module))
        if let error = getCredentialUserIdModuleThrowableError1 {
            throw error
        }
        closureGetCredential()
        return stubbedGetCredentialResult
    }
    // MARK: - upsertCredential
    public var upsertCredentialUserIdCredentialModuleThrowableError2: Error?
    public var closureUpsertCredential: () -> () = {}
    public var invokedUpsertCredentialfunction = false
    public var invokedUpsertCredentialCount = 0
    public var invokedUpsertCredentialParameters: (userId: String, credential: AuthCredential, module: PassModule)?
    public var invokedUpsertCredentialParametersList = [(userId: String, credential: AuthCredential, module: PassModule)]()

    public func upsertCredential(userId: String, credential: AuthCredential, module: PassModule) async throws {
        invokedUpsertCredentialfunction = true
        invokedUpsertCredentialCount += 1
        invokedUpsertCredentialParameters = (userId, credential, module)
        invokedUpsertCredentialParametersList.append((userId, credential, module))
        if let error = upsertCredentialUserIdCredentialModuleThrowableError2 {
            throw error
        }
        closureUpsertCredential()
    }
    // MARK: - removeAllCredentials
    public var removeAllCredentialsUserIdThrowableError3: Error?
    public var closureRemoveAllCredentials: () -> () = {}
    public var invokedRemoveAllCredentialsfunction = false
    public var invokedRemoveAllCredentialsCount = 0
    public var invokedRemoveAllCredentialsParameters: (userId: String, Void)?
    public var invokedRemoveAllCredentialsParametersList = [(userId: String, Void)]()

    public func removeAllCredentials(userId: String) async throws {
        invokedRemoveAllCredentialsfunction = true
        invokedRemoveAllCredentialsCount += 1
        invokedRemoveAllCredentialsParameters = (userId, ())
        invokedRemoveAllCredentialsParametersList.append((userId, ()))
        if let error = removeAllCredentialsUserIdThrowableError3 {
            throw error
        }
        closureRemoveAllCredentials()
    }
}
