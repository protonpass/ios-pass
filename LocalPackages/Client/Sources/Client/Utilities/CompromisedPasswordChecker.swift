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
// sourcery: AutoMockable
public protocol CompromisedPasswordCheckerProtocol: Sendable {
    /// Returns the set of item Ids (itemId + shareId) whose password is present in the breach corpus.
    /// An Id absent from the set is either not breached or "unknown" (e.g. an uncached item whose
    /// network query failed) — callers must not distinguish the two. Per-prefix network/parse failures
    /// keep cached results; symmetric-key, local-cache and corpus-timestamp failures throw.
    ///
    /// The full corpus re-scan runs at most once per rolling 24h; a created or updated login is a
    /// cache-miss and is checked immediately regardless of that window.
    func check(userId: String,
               candidates: [CompromisedPasswordCandidate]) async throws -> Set<String>
}

public final class CompromisedPasswordChecker: CompromisedPasswordCheckerProtocol, Sendable {
    private let remoteDatasource: any RemoteCompromisedPasswordsDatasourceProtocol
    private let localDatasource: any LocalCompromisedPasswordDatasourceProtocol
    private let localTimestampDatasource: any LocalTimestampDatasourceProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let dateProvider: any CurrentDateProviderProtocol
    private let maxConcurrentRequests: Int
    private let logger: Logger

    public init(remoteDatasource: any RemoteCompromisedPasswordsDatasourceProtocol,
                localDatasource: any LocalCompromisedPasswordDatasourceProtocol,
                localTimestampDatasource: any LocalTimestampDatasourceProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                logManager: any LogManagerProtocol,
                maxConcurrentRequests: Int = 8,
                dateProvider: any CurrentDateProviderProtocol) {
        self.remoteDatasource = remoteDatasource
        self.localDatasource = localDatasource
        self.localTimestampDatasource = localTimestampDatasource
        self.symmetricKeyProvider = symmetricKeyProvider
        self.dateProvider = dateProvider
        self.maxConcurrentRequests = maxConcurrentRequests
        logger = .init(manager: logManager)
    }
}

public extension CompromisedPasswordChecker {
    func check(userId: String,
               candidates: [CompromisedPasswordCandidate]) async throws -> Set<String> {
        logger.info("Checking compromised password for \(candidates.count) login items")

        let candidatesWithPasswords = candidates.filter { !$0.password.isEmpty }
        guard !candidatesWithPasswords.isEmpty else { return [] }

        let key = try await symmetricKeyProvider.getSymmetricKey()

        let derivedCandidates = candidatesWithPasswords.map { DerivedCompromisedPasswordCandidate(candidate: $0,
                                                                                                  key: key) }

        let cached = try await loadCachedChecks(userId: userId, derived: derivedCandidates)

        let now = Int(dateProvider.getCurrentDate().timeIntervalSince1970)
        let lastRun = localTimestampDatasource
            .getTimestamp(key: Constants.CompromisedPasswords.lastRunKey(userId))
        let dueForFullCheck = isDueForFullCheck(now: now, lastRun: lastRun)

        let currentLastChange: Int?
        let corpusUnchanged: Bool
        if dueForFullCheck {
            currentLastChange = try await fetchCurrentLastChange()
            corpusUnchanged = isCorpusUnchanged(current: currentLastChange,
                                                stored: localTimestampDatasource
                                                    .getTimestamp(key: Constants.CompromisedPasswords
                                                        .lastCorpusChangeKey(userId)))
        } else {
            // Within the 24h window: skip the remote corpus call and assume the corpus is stable.
            // Unchanged passwords are reused from cache; a new/updated login is a hash-miss in
            // `partition(...)` and is still range-queried immediately.
            currentLastChange = nil
            corpusUnchanged = true
        }

        let (reusable, toCheck) = partition(derivedCandidates, cached: cached, corpusUnchanged: corpusUnchanged)

        var results = reusable
        var allSucceeded = true
        if !toCheck.isEmpty {
            print("woot checking remotely \(toCheck)")

            let (checked, succeeded) = await checkRemotely(toCheck, cached: cached, userId: userId)
            results.merge(checked) { _, new in new }
            allSucceeded = succeeded
        }

        // Advance the freshness marker only when nothing failed, so a partial failure forces a
        // re-check next scan rather than masking a stale result.
        if let currentLastChange, allSucceeded {
            localTimestampDatasource.setTimestamp(currentLastChange,
                                                  key: Constants.CompromisedPasswords.lastCorpusChangeKey(userId))
        }

        if dueForFullCheck, allSucceeded {
            localTimestampDatasource.setTimestamp(now,
                                                  key: Constants.CompromisedPasswords.lastRunKey(userId))
        }

        logger.info("Finished fetching and checking compromised passwords")
        return Set(results.filter { $0.value > 0 }.map(\.key))
    }
}

private extension CompromisedPasswordChecker {
    func loadCachedChecks(userId: String,
                          derived: [DerivedCompromisedPasswordCandidate]) async throws
        -> [String: CompromisedPasswordCheck] {
        do {
            let list = try await localDatasource.getChecks(userId: userId,
                                                           items: derived)
            return Dictionary(list.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
        } catch {
            logger.warning("Failed to fetch locally stored items password checks")
            throw error
        }
    }

    func fetchCurrentLastChange() async throws -> Int? {
        do {
            return try await remoteDatasource.getLastChangeTimestamp()
        } catch {
            logger.warning("Failed to fetch last timestamp for compromised password")
            throw error
        }
    }

    func isCorpusUnchanged(current: Int?, stored: Int?) -> Bool {
        guard let current, let stored else { return false }
        return current <= stored
    }

    func isDueForFullCheck(now: Int, lastRun: Int?) -> Bool {
        guard let lastRun else { return true }
        let elapsed = now - lastRun
        guard elapsed >= 0 else { return true }
        return elapsed >= Constants.CompromisedPasswords.minimumCheckInterval
    }

    func partition(_ derivedAll: [DerivedCompromisedPasswordCandidate],
                   cached: [String: CompromisedPasswordCheck],
                   corpusUnchanged: Bool)
        -> (reusable: [String: Int], toCheck: [DerivedCompromisedPasswordCandidate]) {
        var reusable = [String: Int]()
        var toCheck = [DerivedCompromisedPasswordCandidate]()
        for derived in derivedAll {
            if corpusUnchanged,
               let row = cached[derived.id],
               row.passwordHash == derived.passwordHash {
                reusable[derived.id] = row.breachCount
            } else {
                toCheck.append(derived)
            }
        }
        return (reusable, toCheck)
    }

    func checkRemotely(_ toCheck: [DerivedCompromisedPasswordCandidate],
                       cached: [String: CompromisedPasswordCheck],
                       userId: String)
        async -> (results: [String: Int], succeeded: Bool) {
        var groups = [String: [DerivedCompromisedPasswordCandidate]]()
        for derived in toCheck {
            groups[derived.prefix, default: []].append(derived)
        }

        let now = Int(dateProvider.getCurrentDate().timeIntervalSince1970)
        let outcomes = await runBounded(groups: groups, cached: cached, now: now)

        var results = [String: Int]()
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
        let storedEtags = Set(derived.compactMap { cached[$0.id]?.etag }.filter { !$0.isEmpty })
        let canConditional = storedEtags.count == 1 && derived.allSatisfy { derived in
            guard let row = cached[derived.id] else {
                return false
            }
            return row.passwordHash == derived.passwordHash && row.prefix == prefix && !row.etag.isEmpty
        }
        let etagToSend = canConditional ? storedEtags.first : nil
        var results = [String: Int]()
        var rows = [CompromisedPasswordCheck]()

        do {
            let response = try await remoteDatasource.query(prefix6: prefix, etag: etagToSend)
            switch response {
            case .notModified:
                for item in derived {
                    guard let row = cached[item.id] else {
                        continue
                    }
                    results[item.id] = row.breachCount
                    rows.append(.init(shareId: item.shareId,
                                      itemId: item.itemId,
                                      passwordHash: row.passwordHash,
                                      prefix: row.prefix,
                                      etag: row.etag,
                                      breachCount: row.breachCount,
                                      checkedAt: now))
                }
                return .init(results: results, rows: rows, succeeded: true)

            case let .modified(newEtag, body):
                let suffixes = parseRange(body)
                for item in derived {
                    let breachCount = suffixes[item.suffix]
                    results[item.id] = breachCount ?? 0
                    rows.append(.init(shareId: item.shareId,
                                      itemId: item.itemId,
                                      passwordHash: item.passwordHash,
                                      prefix: prefix,
                                      etag: newEtag ?? "",
                                      breachCount: breachCount ?? 0,
                                      checkedAt: now))
                }
                return .init(results: results, rows: rows, succeeded: true)
            }
        } catch {
            logger.error(error)
            // Keep cached results on error; never invalidate or mark unbreached.
            for item in derived {
                if let row = cached[item.id] {
                    results[item.id] = row.breachCount
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
            let breachCounts = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
            result[suffix] = breachCounts
        }
        return result
    }
}

// MARK: - Internal data struct

private extension CompromisedPasswordChecker {
    /// A candidate reduced to only what the breach check needs: the item identifiers, the SHA-1
    /// prefix/suffix for the k-anonymity range query, and a keyed fingerprint of the password.
    /// The plaintext `CompromisedPasswordCandidate` is intentionally NOT retained — it is consumed
    /// here and dropped, so the password lives in memory only for the duration of this initializer.
    struct DerivedCompromisedPasswordCandidate: ItemIdentifiable {
        let folderId: String?
        let itemId: String
        let shareId: String
        let prefix: String
        let suffix: String
        /// HMAC-SHA256(appKey, password): the local password-change invalidation key. Never sent.
        let passwordHash: String

        var id: String {
            itemId + shareId
        }

        init(candidate: CompromisedPasswordCandidate, key: SymmetricKey) {
            itemId = candidate.itemId
            shareId = candidate.shareId
            let data = Data(candidate.password.utf8)
            // The SHA-1 prefix/suffix stay unkeyed: they drive the k-anonymity lookup against the
            // breach corpus and must match the server's SHA-1 space.
            let sha1 = Insecure.SHA1.hash(data: data).map { String(format: "%02X", $0) }.joined()
            prefix = String(sha1.prefix(6))
            suffix = String(sha1.dropFirst(6))
            passwordHash = HMAC<SHA256>.authenticationCode(for: data, using: key)
                .map { String(format: "%02x", $0) }.joined()
            folderId = nil
        }
    }

    struct PrefixOutcome {
        /// This contains the full item id (itemId + shareId) and the number of breach linked to the password
        let results: [String: Int]
        let rows: [CompromisedPasswordCheck]
        let succeeded: Bool
    }
}
