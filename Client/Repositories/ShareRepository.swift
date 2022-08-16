//
// ShareRepository.swift
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

import Core

public protocol ShareRepositoryProtocol {
    var userId: String { get }
    var localShareDatasource: LocalShareDatasourceProtocol { get }
    var remoteShareDatasouce: RemoteShareDatasourceProtocol { get }

    func getShares(forceRefresh: Bool) async throws -> [Share]
    @discardableResult
    func createVault(request: CreateVaultRequest) async throws -> Share
}

public extension ShareRepositoryProtocol {
    func getShares(forceRefresh: Bool = false) async throws -> [Share] {
        PPLogger.shared?.log("Getting shares")
        if forceRefresh {
            PPLogger.shared?.log("Force refresh getting shares")
            return try await getSharesFromRemoteAndSaveToLocal()
        }

        let localShares = try await localShareDatasource.getAllShares(userId: userId)
        if localShares.isEmpty {
            PPLogger.shared?.log("No shares in local => Fetching from remote...")
            return try await getSharesFromRemoteAndSaveToLocal()
        }

        PPLogger.shared?.log("Found \(localShares.count) shares in local")
        return localShares
    }

    private func getSharesFromRemoteAndSaveToLocal() async throws -> [Share] {
        PPLogger.shared?.log("Getting shares from remote")
        let remoteShares = try await remoteShareDatasouce.getShares()
        PPLogger.shared?.log("Saving remote shares to local")
        try await localShareDatasource.upsertShares(remoteShares, userId: userId)
        return remoteShares
    }

    func createVault(request: CreateVaultRequest) async throws -> Share {
        let createdVault = try await remoteShareDatasouce.createVault(request: request)
        try await localShareDatasource.upsertShares([createdVault], userId: userId)
        return createdVault
    }
}

final class ShareRepository: ShareRepositoryProtocol {
    let userId: String
    let localShareDatasource: LocalShareDatasourceProtocol
    let remoteShareDatasouce: RemoteShareDatasourceProtocol

    init(userId: String,
         localShareDatasource: LocalShareDatasourceProtocol,
         remoteShareDatasouce: RemoteShareDatasourceProtocol) {
        self.userId = userId
        self.localShareDatasource = localShareDatasource
        self.remoteShareDatasouce = remoteShareDatasouce
    }
}
