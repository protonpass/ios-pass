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
import ProtonCore_Services

public protocol PublicKeyRepositoryProtocol {
    func getPublicKeys(email: String) async throws -> [PublicKey]
}

public struct PublicKeyRepository: PublicKeyRepositoryProtocol {
    let localPublicKeyDatasource: LocalPublicKeyDatasourceProtocol
    let remotePublicKeyDatasource: RemotePublicKeyDatasourceProtocol

    init(localPublicKeyDatasource: LocalPublicKeyDatasourceProtocol,
         remotePublicKeyDatasource: RemotePublicKeyDatasourceProtocol) {
        self.localPublicKeyDatasource = localPublicKeyDatasource
        self.remotePublicKeyDatasource = remotePublicKeyDatasource
    }

    public init(container: NSPersistentContainer, apiService: APIService) {
        self.localPublicKeyDatasource = LocalPublicKeyDatasource(container: container)
        self.remotePublicKeyDatasource = RemotePublicKeyDatasource(apiService: apiService)
    }

    public func getPublicKeys(email: String) async throws -> [PublicKey] {
        PPLogger.shared?.log("Getting public keys for email \(email)")
        let localPublicKeys = try await localPublicKeyDatasource.getPublicKeys(email: email)

        if localPublicKeys.isEmpty {
            PPLogger.shared?.log("No public keys in local for email \(email)")
            PPLogger.shared?.log("Fetching public keys from remote for email \(email)")
            let remotePublicKeys =
            try await remotePublicKeyDatasource.getPublicKeys(email: email)

            let count = remotePublicKeys.count
            PPLogger.shared?.log("Fetched \(count) public keys from remote for email \(email)")
            try await localPublicKeyDatasource.insertPublicKeys(remotePublicKeys,
                                                                email: email)
            PPLogger.shared?.log("Inserted \(count) remote public keys to local for email \(email)")
            return remotePublicKeys
        }

        PPLogger.shared?.log("Found \(localPublicKeys.count) public keys in local for email \(email)")
        return localPublicKeys
    }
}
