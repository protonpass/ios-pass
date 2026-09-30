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
import Core
import CoreMocks
import CryptoKit
import Entities
import Foundation
import Testing

private struct StubDateProvider: CurrentDateProviderProtocol {
    let date: Date
    func getCurrentDate() -> Date { date }
}

@Suite(.tags(.repository))
struct CompromisedPasswordCheckerTests {
    // SHA1("12345") = 8CB2237D0679CA88DB6464EAC60DA96345513964
    private let prefix = "8CB223"
    private let suffix = "7D0679CA88DB6464EAC60DA96345513964"
    // A fixed key so the keyed HMAC fingerprint is deterministic across the SUT and the cache seeds.
    private let symmetricKey = SymmetricKey(data: Data(repeating: 0x07, count: 32))
    // A fixed "now" (UNIX epoch seconds) so the rolling-24h throttle windows are deterministic.
    private let now = 1_000_000

    private var keyProvider: SymmetricKeyProviderMock {
        let mock = SymmetricKeyProviderMock()
        mock.stubbedGetSymmetricKeyResult = symmetricKey
        return mock
    }

    private func makeSUT(remote: RemoteCompromisedPasswordsDatasourceProtocolMock,
                         local: LocalCompromisedPasswordDatasourceProtocolMock,
                         localTimeStamp: LocalTimestampDatasourceProtocol = MockLocalTimestampDatasource(),
                         now: Int = 1_000_000,
                         maxConcurrentRequests: Int = 8) -> CompromisedPasswordChecker {
        let dateProvider = StubDateProvider(date: Date(timeIntervalSince1970: TimeInterval(now)))
        let scanTracker = CompromisedPasswordScanTracker(localTimestampDatasource: localTimeStamp,
                                                         dateProvider: dateProvider)
        return CompromisedPasswordChecker(remoteDatasource: remote,
                                          localDatasource: local,
                                          scanTracker: scanTracker,
                                          symmetricKeyProvider: keyProvider,
                                          logManager: LogManagerProtocolMock(),
                                          maxConcurrentRequests: maxConcurrentRequests,
                                          dateProvider: dateProvider)
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
        remote.stubbedGetLastChangeTimestampResult = 1_000_000
        // The datasource hands back already-gunzipped plain text (SUFFIX:COUNT lines).
        remote.stubbedQueryResult = .modified(etag: "\"v1\"",
                                              body: Data(("0000000000000000000000000000000000:3\n" +
                                                  "\(suffix):31033620\n").utf8))
        local.stubbedGetChecksResult = []
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local)
            .check(userId: "user", candidates: [candidate])

        #expect(results.contains(candidate.id))
        // Only the 6-char prefix is ever transmitted.
        #expect(remote.invokedQueryParameters?.prefix6 == prefix)
    }

    @Test
    func `Reports not breached when the suffix is absent from the range`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        remote.stubbedGetLastChangeTimestampResult = 1_000_000
        remote.stubbedQueryResult = .modified(etag: "\"v1\"",
                                              body: Data("0000000000000000000000000000000000:3\n".utf8))
        local.stubbedGetChecksResult = []
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local)
            .check(userId: "user", candidates: [candidate])

        // A not-breached item is simply absent from the returned set.
        #expect(!results.contains(candidate.id))
    }

    @Test
    func `Skips the network and reuses the cached result when the corpus is unchanged`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()
        let passwordHash = fingerprint("12345")

        remote.stubbedGetLastChangeTimestampResult = 500 // older than the stored marker below
        localTimestamp.setTimestamp(1_000, key: Constants.CompromisedPasswords.lastCorpusChangeKey("user"))
        local.stubbedGetChecksResult = [
            .init(shareId: "share",
                  itemId: "item",
                  passwordHash: passwordHash,
                  prefix: prefix,
                  etag: "\"v1\"",
                  breachCount: 777,
                  checkedAt: 900)
        ]
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate])

        #expect(results.contains(candidate.id))
        #expect(!remote.invokedQueryfunction)
    }

    @Test
    func `Keeps the cached result when the network query fails`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()
        let passwordHash = fingerprint("12345")

        // Corpus reportedly changed (newer than stored), so it tries the network — which fails.
        remote.stubbedGetLastChangeTimestampResult = 2_000
        remote.queryPrefix6EtagThrowableError2 = PassError.compromisePassword(.invalidResponse)
        localTimestamp.setTimestamp(1_000, key: Constants.CompromisedPasswords.lastCorpusChangeKey("user"))
        local.stubbedGetChecksResult = [
            .init(shareId: "share",
                  itemId: "item",
                  passwordHash: passwordHash,
                  prefix: prefix,
                  etag: "\"v1\"",
                  breachCount: 555,
                  checkedAt: 900)
        ]
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate])

        #expect(results.contains(candidate.id))
    }

    @Test
    func `Keeps the cached result and retries next time when the corpus timestamp fetch fails`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()

        remote.getLastChangeTimestampThrowableError1 = PassError.compromisePassword(.invalidResponse)
        local.stubbedGetChecksResult = [
            .init(shareId: "share",
                  itemId: "item",
                  passwordHash: fingerprint("12345"),
                  prefix: prefix,
                  etag: "\"v1\"",
                  breachCount: 555,
                  checkedAt: 900)
        ]
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate])

        #expect(results.contains(candidate.id))
        #expect(!remote.invokedQueryfunction)
        #expect(localTimestamp.getTimestamp(key: Constants.CompromisedPasswords.lastRunKey("user")) == nil)
    }

    @Test
    func `A failing prefix restarts the daily window but keeps the corpus marker`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()

        remote.stubbedGetLastChangeTimestampResult = 2_000
        remote.queryPrefix6EtagThrowableError2 = PassError.compromisePassword(.invalidResponse)
        localTimestamp.setTimestamp(1_000, key: Constants.CompromisedPasswords.lastCorpusChangeKey("user"))
        local.stubbedGetChecksResult = []

        _ = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate()])

        #expect(localTimestamp.getTimestamp(key: Constants.CompromisedPasswords.lastRunKey("user")) == now)
        #expect(localTimestamp
            .getTimestamp(key: Constants.CompromisedPasswords.lastCorpusChangeKey("user")) == 1_000)
    }

    @Test
    func `Removes cached rows of items that are no longer candidates`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()
        localTimestamp.setTimestamp(now - 3_600, key: Constants.CompromisedPasswords.lastRunKey("user"))

        func row(shareId: String, itemId: String) -> CompromisedPasswordCheck {
            .init(shareId: shareId,
                  itemId: itemId,
                  passwordHash: fingerprint("12345"),
                  prefix: prefix,
                  etag: "\"v1\"",
                  breachCount: 1,
                  checkedAt: 900)
        }
        // Same item id in another share (a moved item) and a deleted item
        local.stubbedGetChecksResult = [row(shareId: "share", itemId: "item"),
                                        row(shareId: "otherShare", itemId: "item"),
                                        row(shareId: "share", itemId: "deleted")]

        _ = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate()])

        let removed = try #require(local.invokedRemoveParameters?.staleItemIds.map(\.ids))
        #expect(Set(removed) == [IDs(shareId: "otherShare", itemId: "item"),
                                 IDs(shareId: "share", itemId: "deleted")])
    }

    @Test
    func `Ignores empty passwords`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()

        let results = try await makeSUT(remote: remote, local: local)
            .check(userId: "user", candidates: [candidate(password: "")])

        #expect(results.isEmpty)
        #expect(!remote.invokedQueryfunction)
        #expect(!remote.invokedGetLastChangeTimestampfunction)
    }

    @Test
    func `Resolves every prefix when the fan-out exceeds the concurrency limit`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        remote.stubbedGetLastChangeTimestampResult = 1_000_000
        // A single dummy suffix that matches none of the candidates, so every item resolves as not
        // breached regardless of which prefix it falls under.
        remote.stubbedQueryResult = .modified(etag: "\"v1\"",
                                              body: Data("0000000000000000000000000000000000:3\n".utf8))
        local.stubbedGetChecksResult = []

        // Distinct passwords -> distinct SHA-1 prefixes, more than the concurrency limit, which
        // forces the bounded backfill path.
        let candidates = (0..<12).map {
            CompromisedPasswordCandidate(shareId: "share", itemId: "item-\($0)", password: "password-\($0)")
        }

        let results = try await makeSUT(remote: remote, local: local, maxConcurrentRequests: 2)
            .check(userId: "user", candidates: candidates)

        // With a Set return, not-breached items collapse away: coverage is observed via the query
        // counter (one conditional GET per distinct prefix), and the breached set is empty.
        #expect(remote.invokedQueryCount == 12)
        #expect(results.isEmpty)
    }

    // MARK: - Rolling-24h throttle

    @Test
    func `Within the daily window an unchanged item is served from cache with no network`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()
        let passwordHash = fingerprint("12345")

        // Last full run was 1h ago -> within the 24h window.
        localTimestamp.setTimestamp(now - 3_600, key: Constants.CompromisedPasswords.lastRunKey("user"))
        local.stubbedGetChecksResult = [
            .init(shareId: "share",
                  itemId: "item",
                  passwordHash: passwordHash,
                  prefix: prefix,
                  etag: "\"v1\"",
                  breachCount: 777,
                  checkedAt: 900)
        ]
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate])

        #expect(results.contains(candidate.id))
        // The core throttle guarantee: zero remote calls within the window.
        #expect(!remote.invokedGetLastChangeTimestampfunction)
        #expect(!remote.invokedQueryfunction)
    }

    @Test
    func `Within the daily window a new login is still checked without a corpus fetch`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()

        localTimestamp.setTimestamp(now - 3_600, key: Constants.CompromisedPasswords.lastRunKey("user"))
        // Empty cache -> the login is a cache-miss and must be range-queried immediately.
        local.stubbedGetChecksResult = []
        remote.stubbedQueryResult = .modified(etag: "\"v1\"", body: Data("\(suffix):31033620\n".utf8))
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate])

        #expect(results.contains(candidate.id))
        #expect(remote.invokedQueryfunction)
        // The corpus is not re-validated within the window...
        #expect(!remote.invokedGetLastChangeTimestampfunction)
        // ...and a within-window new-item check must not advance the daily gate.
        let storedRun = localTimestamp.getTimestamp(key: Constants.CompromisedPasswords.lastRunKey("user"))
        #expect(storedRun == now - 3_600)
    }

    @Test
    func `After the daily window elapses a full corpus re-scan runs and advances the marker`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()

        // Last run is older than the 24h window.
        localTimestamp.setTimestamp(now - Constants.CompromisedPasswords.minimumCheckInterval - 3_600,
                                    key: Constants.CompromisedPasswords.lastRunKey("user"))
        remote.stubbedGetLastChangeTimestampResult = 1_000_000
        remote.stubbedQueryResult = .modified(etag: "\"v1\"", body: Data("\(suffix):31033620\n".utf8))
        local.stubbedGetChecksResult = []
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate])

        #expect(results.contains(candidate.id))
        #expect(remote.invokedGetLastChangeTimestampfunction)
        // A successful full run advances the daily marker to "now".
        let storedRun = localTimestamp.getTimestamp(key: Constants.CompromisedPasswords.lastRunKey("user"))
        #expect(storedRun == now)
    }

    @Test
    func `The first run has no marker so it performs a full check and records the run`() async throws {
        let remote = RemoteCompromisedPasswordsDatasourceProtocolMock()
        let local = LocalCompromisedPasswordDatasourceProtocolMock()
        let localTimestamp = MockLocalTimestampDatasource()

        // No lastRun marker seeded.
        remote.stubbedGetLastChangeTimestampResult = 1_000_000
        remote.stubbedQueryResult = .modified(etag: "\"v1\"", body: Data("\(suffix):31033620\n".utf8))
        local.stubbedGetChecksResult = []
        let candidate = candidate()

        let results = try await makeSUT(remote: remote, local: local, localTimeStamp: localTimestamp)
            .check(userId: "user", candidates: [candidate])

        #expect(results.contains(candidate.id))
        #expect(remote.invokedGetLastChangeTimestampfunction)
        let storedRun = localTimestamp.getTimestamp(key: Constants.CompromisedPasswords.lastRunKey("user"))
        #expect(storedRun == now)
    }
}
