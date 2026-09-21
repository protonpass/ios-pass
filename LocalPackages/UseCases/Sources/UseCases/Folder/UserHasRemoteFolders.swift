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
    func execute(userId: String) async throws -> Bool
}

public extension UserHasRemoteFoldersUseCase {
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

    public func execute(userId: String) async throws -> Bool {
        let shares = try await shareRepository.getShares(userId: userId)
            .map(\.share)
            .filter { $0.shareType == .vault }

        let ordered = shares.filter(\.shared) + shares.filter { !$0.shared }

        var anyShareUnanswered = false
        for batch in ordered.chunked(into: batchSize) {
            let outcome = await scan(userId: userId, shares: batch)
            if outcome.foundFolder {
                return true
            }
            anyShareUnanswered = anyShareUnanswered || outcome.anyShareFailed
        }

        if anyShareUnanswered {
            throw UserHasRemoteFoldersError.incompleteScan
        }
        return false
    }
}

enum UserHasRemoteFoldersError: Error {
    /// At least one share could not be reached, so the absence of folders is unproven.
    case incompleteScan
}

private extension UserHasRemoteFolders {
    /// A failing share is isolated rather than aborting the scan, so one revoked or deleted share
    /// left in the local table cannot hide folders present in all the others.
    func scan(userId: String,
              shares: [Share]) async -> (foundFolder: Bool, anyShareFailed: Bool) {
        await withTaskGroup(of: ShareFolderCheck.self) { group in
            for share in shares {
                group.addTask { [remoteFolderDatasource] in
                    do {
                        let page = try await remoteFolderDatasource
                            .getFolders(userId: userId,
                                        shareId: share.shareID,
                                        sinceToken: nil,
                                        pageSize: 1)
                        return page.folders.isEmpty ? .noFolder : .hasFolder
                    } catch {
                        return .failed
                    }
                }
            }

            var anyShareFailed = false
            for await check in group {
                switch check {
                case .hasFolder:
                    group.cancelAll()
                    return (foundFolder: true, anyShareFailed: anyShareFailed)

                case .noFolder:
                    continue

                case .failed:
                    anyShareFailed = true
                }
            }
            return (foundFolder: false, anyShareFailed: anyShareFailed)
        }
    }
}

private enum ShareFolderCheck: Sendable {
    case hasFolder
    case noFolder
    case failed
}
