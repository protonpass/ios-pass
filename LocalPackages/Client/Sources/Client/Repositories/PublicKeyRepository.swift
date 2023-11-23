//
// PublicKeyRepository.swift
// Proton Pass - Created on 17/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Core
import CoreData
import Entities
import ProtonCoreServices

// sourcery: AutoMockable
public protocol PublicKeyRepositoryProtocol {
    func getPublicKeys(email: String) async throws -> [PublicKey]
}

public actor PublicKeyRepository: PublicKeyRepositoryProtocol {
    private let localPublicKeyDatasource: LocalPublicKeyDatasourceProtocol
    private let remotePublicKeyDatasource: RemotePublicKeyDatasourceProtocol
    private let logger: Logger

    public init(localPublicKeyDatasource: LocalPublicKeyDatasourceProtocol,
                remotePublicKeyDatasource: RemotePublicKeyDatasourceProtocol,
                logManager: LogManagerProtocol) {
        self.localPublicKeyDatasource = localPublicKeyDatasource
        self.remotePublicKeyDatasource = remotePublicKeyDatasource
        logger = .init(manager: logManager)
    }
}

public extension PublicKeyRepository {
    func getPublicKeys(email: String) async throws -> [PublicKey] {
        logger.trace("Getting public keys for email \(email)")
        let localPublicKeys = try await localPublicKeyDatasource.getPublicKeys(email: email)

        if localPublicKeys.isEmpty {
            logger.trace("No public keys in local for email \(email)")
            logger.trace("Fetching public keys from remote for email \(email)")
            let remotePublicKeys =
                try await remotePublicKeyDatasource.getPublicKeys(email: email)

            let count = remotePublicKeys.count
            logger.trace("Fetched \(count) public keys from remote for email \(email)")
            try await localPublicKeyDatasource.insertPublicKeys(remotePublicKeys,
                                                                email: email)
            logger.trace("Inserted \(count) remote public keys to local for email \(email)")
            return remotePublicKeys
        }

        logger.trace("Found \(localPublicKeys.count) public keys in local for email \(email)")
        return localPublicKeys
    }
}
