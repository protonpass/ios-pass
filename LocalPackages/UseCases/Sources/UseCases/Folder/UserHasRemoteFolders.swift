//
// UserHasRemoteFolders.swift
// Proton Pass - Created on 18/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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

/// Whether any vault the user can reach contains at least one folder.
///
/// Deliberately remote: a client predating folder support never persisted folders, so the local
/// table is empty for precisely the users this question is asked about. Side-effect free, so both
/// the app's repair check and the AutoFill banner can call it.
public protocol UserHasRemoteFoldersUseCase: Sendable {
    @concurrent
    func execute(userId: String) async throws -> Bool
}

public extension UserHasRemoteFoldersUseCase {
    @concurrent
    func callAsFunction(userId: String) async throws -> Bool {
        try await execute(userId: userId)
    }
}

public struct UserHasRemoteFolders: UserHasRemoteFoldersUseCase {
    private let shareRepository: any ShareRepositoryProtocol
    private let remoteFolderDatasource: any RemoteFolderDatasourceProtocol
    private let batchSize: Int

    public init(shareRepository: any ShareRepositoryProtocol,
                remoteFolderDatasource: any RemoteFolderDatasourceProtocol,
                batchSize: Int = 10) {
        self.shareRepository = shareRepository
        self.remoteFolderDatasource = remoteFolderDatasource
        self.batchSize = batchSize
    }

    @concurrent
    public func execute(userId: String) async throws -> Bool {
        let shares = try await shareRepository.getDecryptedShares(userId: userId)
            .filter { $0.shareType == .vault }

        let ordered = shares.filter(\.shared) + shares.filter { !$0.shared }

        for batch in ordered.chunked(into: batchSize) {
            let batchHasFolder = try await anyShareHasFolder(userId: userId, shares: batch)
            if batchHasFolder {
                return true
            }
        }
        return false
    }
}

private extension UserHasRemoteFolders {
    func anyShareHasFolder(userId: String, shares: [Share]) async throws -> Bool {
        try await withThrowingTaskGroup(of: Bool.self) { group in
            for share in shares {
                group.addTask { [remoteFolderDatasource] in
                    let page = try await remoteFolderDatasource.getFolders(userId: userId,
                                                                           shareId: share.shareID,
                                                                           sinceToken: nil,
                                                                           pageSize: 1)
                    return !page.folders.isEmpty
                }
            }

            for try await hasFolder in group where hasFolder {
                group.cancelAll()
                return true
            }
            return false
        }
    }
}
