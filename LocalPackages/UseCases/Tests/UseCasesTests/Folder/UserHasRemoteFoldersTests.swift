//
// UserHasRemoteFoldersTests.swift
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

@testable import UseCases
import Client
import ClientMocks
import Entities
import EntitiesMocks
import Foundation
import Testing

/// Per-share stub. The generated `RemoteFolderDatasourceProtocolMock` has a single stubbed result,
/// which cannot express "only one of these shares has folders".
private final class FolderDatasourceStub: RemoteFolderDatasourceProtocol, @unchecked Sendable {
    /// `shareId` -> number of folders the backend would report.
    var foldersByShare: [String: Int] = [:]
    var error: (any Error)?
    /// Held inside `getFolders` so requests in the same batch genuinely overlap.
    var delay: Duration = .zero
    private(set) var queriedShareIds: [String] = []
    private(set) var requestedPageSizes: [Int] = []
    private(set) var peakConcurrency = 0
    private var inFlight = 0
    private let lock = NSLock()

    func getFolders(userId: String,
                    shareId: String,
                    sinceToken: String?,
                    pageSize: Int) async throws -> PaginatedFolders {
        lock.withLock {
            queriedShareIds.append(shareId)
            requestedPageSizes.append(pageSize)
            inFlight += 1
            peakConcurrency = max(peakConcurrency, inFlight)
        }
        defer { lock.withLock { inFlight -= 1 } }

        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        if let error {
            throw error
        }
        let count = foldersByShare[shareId] ?? 0
        let folders = (0..<count).map { _ in Folder.random() }
        return .init(total: count, lastToken: nil, folders: folders)
    }

    func getFolder(userId: String, shareId: String, folderId: String) async throws -> Folder {
        fatalError("Not used")
    }

    func create(userId: String, shareId: String, request: CreateFolderRequest) async throws -> Folder {
        fatalError("Not used")
    }

    func delete(userId: String, shareId: String, folderIds: [String]) async throws {
        fatalError("Not used")
    }

    func update(userId: String,
                shareId: String,
                folderId: String,
                request: UpdateFolderRequest) async throws -> Folder {
        fatalError("Not used")
    }

    func move(userId: String,
              shareId: String,
              folderId: String,
              request: MoveFolderRequest) async throws -> Folder {
        fatalError("Not used")
    }
}

private enum TestError: Error {
    case boom
}

@Suite(.serialized)
struct UserHasRemoteFoldersTests {
    private let shareRepository: ShareRepositoryProtocolMock
    private let datasource: FolderDatasourceStub
    private let sut: any UserHasRemoteFoldersUseCase
    private let userId = "test_user_id"

    init() {
        shareRepository = ShareRepositoryProtocolMock()
        datasource = FolderDatasourceStub()
        sut = UserHasRemoteFolders(shareRepository: shareRepository,
                                   remoteFolderDatasource: datasource)
    }

    /// `Share.random` defaults to `targetType: 2` (item), so vaults must be requested explicitly.
    private func vault(_ shareId: String) -> Share {
        .random(shareID: shareId, targetType: 1)
    }

    private func sharedVault(_ shareId: String) -> Share {
        .random(shareID: shareId, targetType: 1, shared: true)
    }

    @Test
    func `Returns false when the user has no shares`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = []

        let result = try await sut(userId: userId)

        #expect(!result)
        #expect(datasource.queriedShareIds.isEmpty)
    }

    @Test
    func `Returns false when no share has folders`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = [vault("a"), vault("b")]

        let result = try await sut(userId: userId)

        #expect(!result)
        #expect(Set(datasource.queriedShareIds) == ["a", "b"])
    }

    @Test
    func `Returns true when any share has folders`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = [vault("a"), vault("b"), vault("c")]
        datasource.foldersByShare = ["b": 1]

        let result = try await sut(userId: userId)

        #expect(result)
    }

    @Test
    func `Item shares are never queried, only vaults`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = [
            vault("vault"),
            .random(shareID: "item", targetType: 2)
        ]

        _ = try await sut(userId: userId)

        #expect(datasource.queriedShareIds == ["vault"])
    }

    @Test
    func `Asks for a single folder per share, since existence is all that matters`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = [vault("a")]

        _ = try await sut(userId: userId)

        #expect(datasource.requestedPageSizes == [1])
    }

    @Test
    func `Propagates datasource errors so the caller can count a failed attempt`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = [vault("a")]
        datasource.error = TestError.boom

        await #expect(throws: TestError.self) {
            try await sut(userId: userId)
        }
    }

    @Test
    func `A positive batch leaves the remaining batches unrequested`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = (0..<6).map { vault("s\($0)") }
        datasource.foldersByShare = ["s1": 1]
        let sut = UserHasRemoteFolders(shareRepository: shareRepository,
                                       remoteFolderDatasource: datasource,
                                       batchSize: 2)

        #expect(try await sut(userId: userId) == true)
        #expect(Set(datasource.queriedShareIds) == ["s0", "s1"])
    }

    @Test
    func `Concurrent requests never exceed the batch size`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = (0..<6).map { vault("s\($0)") }
        datasource.delay = .milliseconds(20)
        let sut = UserHasRemoteFolders(shareRepository: shareRepository,
                                       remoteFolderDatasource: datasource,
                                       batchSize: 2)

        #expect(try await sut(userId: userId) == false)
        #expect(datasource.peakConcurrency <= 2)
        // All shares still get checked when none of them has a folder.
        #expect(datasource.queriedShareIds.count == 6)
    }

    @Test
    func `Shared vaults are checked before private ones`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = [
            vault("private1"),
            vault("private2"),
            sharedVault("shared")
        ]
        datasource.foldersByShare = ["shared": 1]
        // One share per batch makes the ordering observable.
        let sut = UserHasRemoteFolders(shareRepository: shareRepository,
                                       remoteFolderDatasource: datasource,
                                       batchSize: 1)

        #expect(try await sut(userId: userId) == true)
        #expect(datasource.queriedShareIds == ["shared"])
    }

    @Test
    func `Requests within a batch run concurrently, not one after another`() async throws {
        shareRepository.stubbedGetDecryptedSharesResult = (0..<4).map { vault("s\($0)") }
        datasource.delay = .milliseconds(20)
        let sut = UserHasRemoteFolders(shareRepository: shareRepository,
                                       remoteFolderDatasource: datasource,
                                       batchSize: 4)

        _ = try await sut(userId: userId)

        #expect(datasource.peakConcurrency == 4)
    }
}
