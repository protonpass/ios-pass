// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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
// swiftlint:disable all

@testable import Client
import Core
import CryptoKit
import ProtonCore_Login

final class PassKeyManagerProtocolMock: @unchecked Sendable, PassKeyManagerProtocol {
    // MARK: - itemKeyDatasource
    var invokedItemKeyDatasourceSetter = false
    var invokedItemKeyDatasourceSetterCount = 0
    var invokedItemKeyDatasource: RemoteItemKeyDatasourceProtocol?
    var invokedItemKeyDatasourceList = [RemoteItemKeyDatasourceProtocol?]()
    var invokedItemKeyDatasourceGetter = false
    var invokedItemKeyDatasourceGetterCount = 0
    var stubbedItemKeyDatasource: RemoteItemKeyDatasourceProtocol!
    var itemKeyDatasource: RemoteItemKeyDatasourceProtocol {
        set {
            invokedItemKeyDatasourceSetter = true
            invokedItemKeyDatasourceSetterCount += 1
            invokedItemKeyDatasource = newValue
            invokedItemKeyDatasourceList.append(newValue)
        } get {
            invokedItemKeyDatasourceGetter = true
            invokedItemKeyDatasourceGetterCount += 1
            return stubbedItemKeyDatasource
        }
    }
    // MARK: - shareKeyRepository
    var invokedShareKeyRepositorySetter = false
    var invokedShareKeyRepositorySetterCount = 0
    var invokedShareKeyRepository: ShareKeyRepositoryProtocol?
    var invokedShareKeyRepositoryList = [ShareKeyRepositoryProtocol?]()
    var invokedShareKeyRepositoryGetter = false
    var invokedShareKeyRepositoryGetterCount = 0
    var stubbedShareKeyRepository: ShareKeyRepositoryProtocol!
    var shareKeyRepository: ShareKeyRepositoryProtocol {
        set {
            invokedShareKeyRepositorySetter = true
            invokedShareKeyRepositorySetterCount += 1
            invokedShareKeyRepository = newValue
            invokedShareKeyRepositoryList.append(newValue)
        } get {
            invokedShareKeyRepositoryGetter = true
            invokedShareKeyRepositoryGetterCount += 1
            return stubbedShareKeyRepository
        }
    }
    // MARK: - logger
    var invokedLoggerSetter = false
    var invokedLoggerSetterCount = 0
    var invokedLogger: Logger?
    var invokedLoggerList = [Logger?]()
    var invokedLoggerGetter = false
    var invokedLoggerGetterCount = 0
    var stubbedLogger: Logger!
    var logger: Logger {
        set {
            invokedLoggerSetter = true
            invokedLoggerSetterCount += 1
            invokedLogger = newValue
            invokedLoggerList.append(newValue)
        } get {
            invokedLoggerGetter = true
            invokedLoggerGetterCount += 1
            return stubbedLogger
        }
    }
    // MARK: - symmetricKey
    var invokedSymmetricKeySetter = false
    var invokedSymmetricKeySetterCount = 0
    var invokedSymmetricKey: SymmetricKey?
    var invokedSymmetricKeyList = [SymmetricKey?]()
    var invokedSymmetricKeyGetter = false
    var invokedSymmetricKeyGetterCount = 0
    var stubbedSymmetricKey: SymmetricKey!
    var symmetricKey: SymmetricKey {
        set {
            invokedSymmetricKeySetter = true
            invokedSymmetricKeySetterCount += 1
            invokedSymmetricKey = newValue
            invokedSymmetricKeyList.append(newValue)
        } get {
            invokedSymmetricKeyGetter = true
            invokedSymmetricKeyGetterCount += 1
            return stubbedSymmetricKey
        }
    }
    // MARK: - getShareKey
    var getShareKeyShareIdKeyRotationThrowableError: Error?
    var closureGetShareKey: () -> () = {}
    var invokedGetShareKey = false
    var invokedGetShareKeyCount = 0
    var invokedGetShareKeyParameters: (shareId: String, keyRotation: Int64)?
    var invokedGetShareKeyParametersList = [(shareId: String, keyRotation: Int64)]()
    var stubbedGetShareKeyResult: DecryptedShareKey!

    func getShareKey(shareId: String, keyRotation: Int64) async throws -> DecryptedShareKey {
        invokedGetShareKey = true
        invokedGetShareKeyCount += 1
        invokedGetShareKeyParameters = (shareId, keyRotation)
        invokedGetShareKeyParametersList.append((shareId, keyRotation))
        if let error = getShareKeyShareIdKeyRotationThrowableError {
            throw error
        }
        closureGetShareKey()
        return stubbedGetShareKeyResult
    }
    // MARK: - getLatestShareKey
    var getLatestShareKeyShareIdThrowableError: Error?
    var closureGetLatestShareKey: () -> () = {}
    var invokedGetLatestShareKey = false
    var invokedGetLatestShareKeyCount = 0
    var invokedGetLatestShareKeyParameters: (shareId: String, Void)?
    var invokedGetLatestShareKeyParametersList = [(shareId: String, Void)]()
    var stubbedGetLatestShareKeyResult: DecryptedShareKey!

    func getLatestShareKey(shareId: String) async throws -> DecryptedShareKey {
        invokedGetLatestShareKey = true
        invokedGetLatestShareKeyCount += 1
        invokedGetLatestShareKeyParameters = (shareId, ())
        invokedGetLatestShareKeyParametersList.append((shareId, ()))
        if let error = getLatestShareKeyShareIdThrowableError {
            throw error
        }
        closureGetLatestShareKey()
        return stubbedGetLatestShareKeyResult
    }
    // MARK: - getLatestItemKey
    var getLatestItemKeyShareIdItemIdThrowableError: Error?
    var closureGetLatestItemKey: () -> () = {}
    var invokedGetLatestItemKey = false
    var invokedGetLatestItemKeyCount = 0
    var invokedGetLatestItemKeyParameters: (shareId: String, itemId: String)?
    var invokedGetLatestItemKeyParametersList = [(shareId: String, itemId: String)]()
    var stubbedGetLatestItemKeyResult: DecryptedItemKey!

    func getLatestItemKey(shareId: String, itemId: String) async throws -> DecryptedItemKey {
        invokedGetLatestItemKey = true
        invokedGetLatestItemKeyCount += 1
        invokedGetLatestItemKeyParameters = (shareId, itemId)
        invokedGetLatestItemKeyParametersList.append((shareId, itemId))
        if let error = getLatestItemKeyShareIdItemIdThrowableError {
            throw error
        }
        closureGetLatestItemKey()
        return stubbedGetLatestItemKeyResult
    }
}
