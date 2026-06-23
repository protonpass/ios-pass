//
// CompromisedPasswordChecker.swift
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

import Core
@preconcurrency import CryptoKit
import Entities
import Foundation

/// Detects passwords present in a breach corpus via the k-anonymity range-query model, honouring
/// the corpus `last_change` freshness gate and per-prefix `ETag` conditional requests. The full
/// password/hash never leaves the device — only the 6-character SHA-1 prefix is transmitted.
///
/// Lives in the Client layer (not as a UseCase) so `PassMonitorRepository` — which is also in
/// Client and cannot import UseCases — can drive it directly from its weakness computation.
// sourcery: AutoMockable
public protocol CompromisedPasswordCheckerProtocol: Sendable {
    /// Returns a map of itemId → result. Items omitted from the map are "unknown" (e.g. an
    /// uncached item whose network query failed) and must NOT be treated as breached. The check is
    /// resilient: network/parse failures keep cached results rather than throwing.
    func check(userId: String,
               candidates: [CompromisedPasswordCandidate]) async -> [String: CompromisedPasswordResult]
}

public final class CompromisedPasswordChecker: CompromisedPasswordCheckerProtocol, Sendable {
    private let remoteDatasource: any RemoteCompromisedPasswordsDatasourceProtocol
    private let localDatasource: any LocalCompromisedPasswordDatasourceProtocol
    private let currentDate: @Sendable () -> Date
    private let maxConcurrentRequests: Int
    private let logger: Logger

    public init(remoteDatasource: any RemoteCompromisedPasswordsDatasourceProtocol,
                localDatasource: any LocalCompromisedPasswordDatasourceProtocol,
                logManager: any LogManagerProtocol,
                maxConcurrentRequests: Int = 8,
                currentDate: @escaping @Sendable () -> Date = { Date() }) {
        self.remoteDatasource = remoteDatasource
        self.localDatasource = localDatasource
        self.currentDate = currentDate
        self.maxConcurrentRequests = maxConcurrentRequests
        logger = .init(manager: logManager)
    }
}

public extension CompromisedPasswordChecker {
    func check(userId: String,
               candidates: [CompromisedPasswordCandidate]) async -> [String: CompromisedPasswordResult] {
        logger.info("Checking compromised password for \(candidates.count) login items")

        let derivedAll = candidates
            .filter { !$0.password.isEmpty }
            .map { DerivedCompromisedPasswordCandidate(candidate: $0) }
        guard !derivedAll.isEmpty else { return [:] }

        let cached = await loadCachedChecks(userId: userId, derived: derivedAll)
        let currentLastChange = await fetchCurrentLastChange()
        let corpusUnchanged = isCorpusUnchanged(current: currentLastChange,
                                                stored: localDatasource.getLastChange(userId: userId))

        let (reusable, toCheck) = partition(derivedAll, cached: cached, corpusUnchanged: corpusUnchanged)

        var results = reusable
        var allSucceeded = true
        if !toCheck.isEmpty {
            let (checked, succeeded) = await checkRemotely(toCheck, cached: cached, userId: userId)
            results.merge(checked) { _, new in new }
            allSucceeded = succeeded
        }

        // Advance the freshness marker only when nothing failed, so a partial failure forces a
        // re-check next scan rather than masking a stale result.
        if let currentLastChange, allSucceeded {
            localDatasource.setLastChange(currentLastChange, userId: userId)
        }

        logger.info("Finished fetching and checking compromised passwords")
        return results
    }
}

private extension CompromisedPasswordChecker {
    func loadCachedChecks(userId: String,
                          derived: [DerivedCompromisedPasswordCandidate]) async
        -> [String: CompromisedPasswordCheck] {
        do {
            let list = try await localDatasource.getChecks(userId: userId,
                                                           itemIds: derived.map(\.candidate.itemId))
            return Dictionary(list.map { ($0.itemId, $0) }, uniquingKeysWith: { _, new in new })
        } catch {
            logger.warning("Failed to fetch locally stored items password checks")
            return [:]
        }
    }

    func fetchCurrentLastChange() async -> Int? {
        do {
            return try await remoteDatasource.lastChange()
        } catch {
            logger.warning("Failed to fetch last timestamp for compromised password")
            return nil
        }
    }

    func isCorpusUnchanged(current: Int?, stored: Int?) -> Bool {
        guard let current, let stored else { return false }
        return current <= stored
    }

    func partition(_ derivedAll: [DerivedCompromisedPasswordCandidate],
                   cached: [String: CompromisedPasswordCheck],
                   corpusUnchanged: Bool)
        -> (reusable: [String: CompromisedPasswordResult], toCheck: [DerivedCompromisedPasswordCandidate]) {
        var reusable = [String: CompromisedPasswordResult]()
        var toCheck = [DerivedCompromisedPasswordCandidate]()
        for derived in derivedAll {
            if corpusUnchanged,
               let row = cached[derived.candidate.itemId],
               row.passwordHash == derived.passwordHash {
                reusable[derived.candidate.itemId] = .init(breached: row.breached, count: row.count)
            } else {
                toCheck.append(derived)
            }
        }
        return (reusable, toCheck)
    }

    func checkRemotely(_ toCheck: [DerivedCompromisedPasswordCandidate],
                       cached: [String: CompromisedPasswordCheck],
                       userId: String)
        async -> (results: [String: CompromisedPasswordResult], succeeded: Bool) {
        var groups = [String: [DerivedCompromisedPasswordCandidate]]()
        for derived in toCheck {
            groups[derived.prefix, default: []].append(derived)
        }
        let now = Int(currentDate().timeIntervalSince1970)
        let outcomes = await runBounded(groups: groups, cached: cached, now: now)

        var results = [String: CompromisedPasswordResult]()
        var rows = [CompromisedPasswordCheck]()
        var allSucceeded = true
        for outcome in outcomes {
            results.merge(outcome.results) { _, new in new }
            rows.append(contentsOf: outcome.rows)
            allSucceeded = allSucceeded && outcome.succeeded
        }
        if !rows.isEmpty {
            do {
                try await localDatasource.upsert(rows, userId: userId)
            } catch {
                logger.warning("Failed to upsert \(rows.count) CompromisedPasswordCheck")
            }
        }
        return (results, allSucceeded)
    }

    /// Runs one conditional GET per prefix with bounded concurrency.
    func runBounded(groups: [String: [DerivedCompromisedPasswordCandidate]],
                    cached: [String: CompromisedPasswordCheck],
                    now: Int) async -> [PrefixOutcome] {
        await Array(groups).parallelMap(parallelism: maxConcurrentRequests) { entry in
            await self.process(prefix: entry.0, derived: entry.1, cached: cached, now: now)
        }
    }

    func process(prefix: String,
                 derived: [DerivedCompromisedPasswordCandidate],
                 cached: [String: CompromisedPasswordCheck],
                 now: Int) async -> PrefixOutcome {
        // Only reuse a stored ETag (and thus accept a 304) when every item in this prefix has a
        // matching, still-valid cached result to fall back on — otherwise force a fresh body.
        let storedEtags = Set(derived.compactMap { cached[$0.candidate.itemId]?.etag }.filter { !$0.isEmpty })
        let canConditional = storedEtags.count == 1 && derived.allSatisfy { derived in
            guard let row = cached[derived.candidate.itemId] else {
                return false
            }
            return row.passwordHash == derived.passwordHash && row.prefix == prefix && !row.etag.isEmpty
        }
        let etagToSend = canConditional ? storedEtags.first : nil
        var results = [String: CompromisedPasswordResult]()
        var rows = [CompromisedPasswordCheck]()

        do {
            let response = try await remoteDatasource.query(prefix6: prefix, etag: etagToSend)
            switch response {
            case .notModified:
                for item in derived {
                    guard let row = cached[item.candidate.itemId] else {
                        continue
                    }
                    results[item.candidate.itemId] = .init(breached: row.breached, count: row.count)
                    rows.append(.init(shareId: item.candidate.shareId,
                                      itemId: item.candidate.itemId,
                                      passwordHash: row.passwordHash,
                                      prefix: row.prefix,
                                      etag: row.etag,
                                      breached: row.breached,
                                      count: row.count,
                                      checkedAt: now))
                }
                return .init(results: results, rows: rows, succeeded: true)

            case let .modified(newEtag, body):
                let suffixes = parseRange(body)
                for item in derived {
                    let count = suffixes[item.suffix]
                    let breached = count != nil
                    results[item.candidate.itemId] = .init(breached: breached, count: count ?? 0)
                    rows.append(.init(shareId: item.candidate.shareId,
                                      itemId: item.candidate.itemId,
                                      passwordHash: item.passwordHash,
                                      prefix: prefix,
                                      etag: newEtag ?? "",
                                      breached: breached,
                                      count: count ?? 0,
                                      checkedAt: now))
                }
                return .init(results: results, rows: rows, succeeded: true)
            }
        } catch {
            logger.error(error)
            // Keep cached results on error; never invalidate or mark unbreached.
            for item in derived {
                if let row = cached[item.candidate.itemId] {
                    results[item.candidate.itemId] = .init(breached: row.breached, count: row.count)
                }
            }
            return .init(results: results, rows: [], succeeded: false)
        }
    }

    /// Parses `SUFFIX:COUNT` lines into a suffix → count map. Padding entries (from
    /// `Add-Padding`) simply never match a real suffix, so they are harmless.
    func parseRange(_ body: Data) -> [String: Int] {
        guard let text = String(data: body, encoding: .utf8) else {
            return [:]
        }
        var result = [String: Int]()
        for line in text.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else {
                continue
            }
            let suffix = parts[0].trimmingCharacters(in: .whitespaces).uppercased()
            let count = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
            result[suffix] = count
        }
        return result
    }
}

// MARK: - Internal data struct

private extension CompromisedPasswordChecker {
    /// A candidate with its derived SHA-1 prefix/suffix and SHA-256 password hash.
    struct DerivedCompromisedPasswordCandidate {
        let candidate: CompromisedPasswordCandidate
        let prefix: String
        let suffix: String
        let passwordHash: String

        init(candidate: CompromisedPasswordCandidate) {
            self.candidate = candidate
            let data = Data(candidate.password.utf8)
            let sha1 = Insecure.SHA1.hash(data: data).map { String(format: "%02X", $0) }.joined()
            prefix = String(sha1.prefix(6))
            suffix = String(sha1.dropFirst(6))
            passwordHash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        }
    }

    struct PrefixOutcome {
        let results: [String: CompromisedPasswordResult]
        let rows: [CompromisedPasswordCheck]
        let succeeded: Bool
    }
}
