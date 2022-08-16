//
// ShareKeysRepository.swift
// Proton Pass - Created on 16/08/2022.
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

import Foundation

public protocol ShareKeysRepositoryProtocol {
    var localShareKeysDatasource: LocalShareKeysDatasourceProtocol { get }
    var remoteShareKeysDatasource: RemoteShareKeysDatasourceProtocol { get }

    func getShareKeys(shareId: String, page: Int, pageSize: Int) async throws -> ShareKeys
}

public extension ShareKeysRepositoryProtocol {
    func getShareKeys(shareId: String, page: Int, pageSize: Int) async throws -> ShareKeys {
        let localShareKeys =
        try await localShareKeysDatasource.getShareKeys(shareId: shareId,
                                                        page: page,
                                                        pageSize: pageSize)

        if localShareKeys.isEmpty {
            let remoteShareKeys =
            try await remoteShareKeysDatasource.getShareKeys(shareId: shareId,
                                                             page: page,
                                                             pageSize: pageSize)
            try await localShareKeysDatasource.upsertShareKeys(remoteShareKeys,
                                                               shareId: shareId)
            return remoteShareKeys
        }

        return localShareKeys
    }
}

public struct ShareKeysRepository: ShareKeysRepositoryProtocol {
    public let localShareKeysDatasource: LocalShareKeysDatasourceProtocol
    public let remoteShareKeysDatasource: RemoteShareKeysDatasourceProtocol

    public init(localShareKeysDatasource: LocalShareKeysDatasourceProtocol,
                remoteShareKeysDatasource: RemoteShareKeysDatasourceProtocol) {
        self.localShareKeysDatasource = localShareKeysDatasource
        self.remoteShareKeysDatasource = remoteShareKeysDatasource
    }
}
