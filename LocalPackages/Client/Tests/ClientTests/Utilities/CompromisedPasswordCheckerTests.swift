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

final class MockLocalTimestampDatasource: LocalTimestampDatasourceProtocol, @unchecked Sendable {
    var currentTimestamp: Int?
    
    /// Cached UNIX epoch seconds of the corpus's last change at the previous successful scan.
    func getLastChangeTimestamp(key: String) -> Int? {
        currentTimestamp
    }

    /// Persist (or clear with `nil`) the corpus freshness marker.
    func setLastChangeTimestamp(_ value: Int?, key: String) {
        currentTimestamp = value
    }
}

@Suite(.tags(.repository))
struct CompromisedPasswordCheckerTests {
    // SHA1("12345") = 8CB2237D0679CA88DB6464EAC60DA96345513964
    private let prefix = "8CB223"
    private let suffix = "7D0679CA88DB6464EAC60DA96345513964"
    // A fixed key so the keyed HMAC fingerprint is deterministic across the SUT and the cache seeds.
    private let symmetricKey = SymmetricKey(data: Data(repeating: 0x07, count: 32))

    private var keyProvider: SymmetricKeyProviderMock {
        let mock = SymmetricKeyProviderMock()
        mock.stubbedGetSymmetricKeyResult = symmetricKey
        return mock
    }

    private func makeSUT(remote: RemoteCompromisedPasswordsDatasourceProtocolMock,
                         local: LocalCompromisedPasswordDatasourceProtocolMock,
                         localTimeStamp: LocalTimestampDatasourceProtocol = MockLocalTimestampDatasource(),
                         maxConcurrentRequests: Int = 8) -> CompromisedPasswordChecker {
        CompromisedPasswordChecker(remoteDatasource: remote,
                                   localDatasource: local,
                                   localTimestampDatasource: localTimeStamp,
                                   symmetricKeyProvider: keyProvider,
                                   logManager: LogManagerProtocolMock(),
                                   maxConcurrentRequests: maxConcurrentRequests,
                                   currentDate: { Date(timeIntervalSince1970: 1_000_000) })
    }

    /// The persisted fingerprint is HMAC-SHA256(appKey, password); mirror it for cache seeds.
    private func fingerprint(_ password: String) -> String {
        HMAC<SHA256>.authenticationCode(for: Data(password.utf8), using: symmetricKey)
            .map { String(format: "%02x", $0) }.joined()
    }

    private func candidate(password: String = "12345") -> CompromisedPasswordCandidate {
        .init(shareId: "share", itemId: "item", password: password)
    }

    @Test
    func `Detects the 12345 breach vector via k-anonymity`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()
        remote.stubbedLastChangeResult = 1_000_000
        // The datasource hands back already-gunzipped plain text (SUFFIX:COUNT lines).
        remote.stubbedQueryResult = .modified(etag: "\"v1\"",
                                              body: Data(("0000000000000000000000000000000000:3\n" +
                                                  "\(suffix):31033620\n").utf8))
        local.stubbedGetChecksUserIdItemsAsyncResult2 = []

        let results = await makeSUT(remote: remote, local: local,
                                    localTimeStamp: localTimestamp).check(userId: "user",
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
        local.stubbedGetChecksUserIdItemsAsyncResult2 = []

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
        let localTimestamp = MockLocalTimestampDatasource()
        let passwordHash = fingerprint("12345")

        remote.stubbedLastChangeResult = 500 // older than the stored marker below
        localTimestamp.setLastChangeTimestamp(1_000, key: localTimestamp.lastChangeKey("user"))
        local.stubbedGetChecksUserIdItemsAsyncResult2 = [
            .init(shareId: "share",
                  itemId: "item",
                  passwordHash: passwordHash,
                  prefix: prefix,
                  etag: "\"v1\"",
                  breached: true,
                  count: 777,
                  checkedAt: 900)
        ]

        let results = await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp).check(userId: "user",
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
        let localTimestamp = MockLocalTimestampDatasource()

        let passwordHash = fingerprint("12345")

        // Corpus reportedly changed (newer than stored), so it tries the network — which fails.
        remote.stubbedLastChangeResult = 2_000
        remote.queryPrefix6EtagThrowableError2 = PassError.compromisePassword(.invalidResponse)
        localTimestamp.setLastChangeTimestamp(1_000, key: localTimestamp.lastChangeKey("user"))

        local.stubbedGetChecksUserIdItemsAsyncResult2 = [
            .init(shareId: "share",
                  itemId: "item",
                  passwordHash: passwordHash,
                  prefix: prefix,
                  etag: "\"v1\"",
                  breached: true,
                  count: 555,
                  checkedAt: 900)
        ]

        let results = await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp).check(userId: "user",
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

    @Test
    func `Resolves every prefix when the fan-out exceeds the concurrency limit`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        remote.stubbedLastChangeResult = 1_000_000
        // A single dummy suffix that matches none of the candidates, so every item resolves as not
        // breached regardless of which prefix it falls under.
        remote.stubbedQueryResult = .modified(etag: "\"v1\"",
                                              body: Data("0000000000000000000000000000000000:3\n".utf8))
        local.stubbedGetChecksUserIdItemsAsyncResult2 = []

        // Distinct passwords -> distinct SHA-1 prefixes, more than the concurrency limit, which
        // forces the bounded backfill path.
        let candidates = (0..<12).map {
            CompromisedPasswordCandidate(shareId: "share", itemId: "item-\($0)", password: "password-\($0)")
        }

        let results = await makeSUT(remote: remote, local: local, maxConcurrentRequests: 2)
            .check(userId: "user", candidates: candidates)

        // Every candidate is resolved exactly once, none breached.
        #expect(results.count == candidates.count)
        for candidate in candidates {
            let result = try #require(results[candidate.itemId])
            #expect(!result.breached)
            #expect(result.count == 0)
        }
    }
}
