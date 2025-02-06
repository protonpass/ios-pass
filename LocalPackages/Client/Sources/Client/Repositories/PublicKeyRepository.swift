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
import Entities

// sourcery: AutoMockable
public protocol PublicKeyRepositoryProtocol: Sendable {
    func getPublicKeys(email: String) async throws -> [PublicKey]
}

public actor PublicKeyRepository: PublicKeyRepositoryProtocol {
    private let datasource: any RemotePublicKeyDatasourceProtocol
    private let userManager: any UserManagerProtocol
    private let logger: Logger

    public init(datasource: any RemotePublicKeyDatasourceProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.datasource = datasource
        self.userManager = userManager
        logger = .init(manager: logManager)
    }
}

public extension PublicKeyRepository {
    func getPublicKeys(email: String) async throws -> [PublicKey] {
        logger.trace("Getting public keys for email \(email)")
        let userId = try await userManager.getActiveUserId()
        let keys = try await datasource.getPublicKeys(userId: userId, email: email)
        logger.trace("Got \(keys.count) public keys for email \(email)")
        return keys
    }
}
