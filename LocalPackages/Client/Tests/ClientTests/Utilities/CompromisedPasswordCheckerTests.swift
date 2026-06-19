//
// CompromisedPasswordCheckerTests.swift
// Proton Pass - Created on 18/06/2026.
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

@testable import Client
import ClientMocks
import CoreMocks
import CryptoKit
import Entities
import Foundation
import Testing

@Suite(.tags(.repository))
struct CompromisedPasswordCheckerTests {
    // SHA1("12345") = 8CB2237D0679CA88DB6464EAC60DA96345513964
    private let prefix = "8CB223"
    private let suffix = "7D0679CA88DB6464EAC60DA96345513964"

    private func makeSUT(remote: RemoteCompromisedPasswordsDatasourceProtocolMock,
                         local: LocalCompromisedPasswordDatasourceProtocolMock) -> CompromisedPasswordChecker {
        CompromisedPasswordChecker(remoteDatasource: remote,
                                   localDatasource: local,
                                   logManager: LogManagerProtocolMock(),
                                   currentDate: { Date(timeIntervalSince1970: 1_000_000) })
    }

    private func candidate(password: String = "12345") -> CompromisedPasswordCandidate {
        .init(shareId: "share", itemId: "item", password: password)
    }

    @Test
    func `Detects the 12345 breach vector via k-anonymity`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        remote.stubbedLastChangeResult = 1_000_000
        // The datasource hands back already-gunzipped plain text (SUFFIX:COUNT lines).
        remote.stubbedQueryResult = .modified(etag: "\"v1\"",
                                              body: Data(("0000000000000000000000000000000000:3\n" +
                                                  "\(suffix):31033620\n").utf8))
        local.stubbedGetChecksUserIdItemIdsAsyncResult2 = []
        local.stubbedGetLastChangeResult = nil

        let results = await makeSUT(remote: remote, local: local).check(userId: "user",
                                                                        candidates: [candidate()])

        let result = try #require(results["item"])
        #expect(result.breached)
        #expect(result.count == 31_033_620)
        // Only the 6-char prefix is ever transmitted.
        #expect(remote.invokedQueryParameters?.prefix6 == prefix)
    }

    @Test
    func `Reports not breached when the suffix is absent from the range`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        remote.stubbedLastChangeResult = 1_000_000
        remote.stubbedQueryResult = .modified(etag: "\"v1\"",
                                              body: Data("0000000000000000000000000000000000:3\n".utf8))
        local.stubbedGetChecksUserIdItemIdsAsyncResult2 = []
        local.stubbedGetLastChangeResult = nil

        let results = await makeSUT(remote: remote, local: local).check(userId: "user",
                                                                        candidates: [candidate()])

        let result = try #require(results["item"])
        #expect(!result.breached)
        #expect(result.count == 0)
    }

    @Test
    func `Skips the network and reuses the cached result when the corpus is unchanged`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let passwordHash = SHA256.hash(data: Data("12345".utf8)).map { String(format: "%02x", $0) }.joined()

        remote.stubbedLastChangeResult = 500 // older than the stored marker below
        local.stubbedGetLastChangeResult = 1_000
        local.stubbedGetChecksUserIdItemIdsAsyncResult2 = [
            .init(shareId: "share",
                  itemId: "item",
                  passwordHash: passwordHash,
                  prefix: prefix,
                  etag: "\"v1\"",
                  breached: true,
                  count: 777,
                  checkedAt: 900)
        ]

        let results = await makeSUT(remote: remote, local: local).check(userId: "user",
                                                                        candidates: [candidate()])

        let result = try #require(results["item"])
        #expect(result.breached)
        #expect(result.count == 777)
        #expect(!remote.invokedQueryfunction)
    }

    @Test
    func `Keeps the cached result when the network query fails`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let passwordHash = SHA256.hash(data: Data("12345".utf8)).map { String(format: "%02x", $0) }.joined()

        // Corpus reportedly changed (newer than stored), so it tries the network — which fails.
        remote.stubbedLastChangeResult = 2_000
        remote.queryPrefix6EtagThrowableError2 = CompromisedPasswordsNetworkError.invalidResponse
        local.stubbedGetLastChangeResult = 1_000
        local.stubbedGetChecksUserIdItemIdsAsyncResult2 = [
            .init(shareId: "share",
                  itemId: "item",
                  passwordHash: passwordHash,
                  prefix: prefix,
                  etag: "\"v1\"",
                  breached: true,
                  count: 555,
                  checkedAt: 900)
        ]

        let results = await makeSUT(remote: remote, local: local).check(userId: "user",
                                                                        candidates: [candidate()])

        let result = try #require(results["item"])
        #expect(result.breached)
        #expect(result.count == 555)
    }

    @Test
    func `Ignores empty passwords`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()

        let results = await makeSUT(remote: remote, local: local).check(userId: "user",
                                                                        candidates: [candidate(password: "")])

        #expect(results.isEmpty)
        #expect(!remote.invokedQueryfunction)
        #expect(!remote.invokedLastChangefunction)
    }
}
