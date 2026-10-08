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
/// password/hash never leaves the device - only the 6-character SHA-1 prefix is transmitted.
// sourcery: AutoMockable
public protocol CompromisedPasswordCheckerProtocol: Sendable {
    /// Returns the set of item Ids (itemId + shareId) whose password is present in the breach corpus.
    /// An Id absent from the set is either not breached or "unknown" (e.g. an uncached item whose
    /// network query failed) - callers must not distinguish the two. Per-prefix network/parse failures
    /// and corpus-timestamp failures keep cached results; symmetric-key and local-cache failures throw.
    ///
    /// The full corpus re-scan runs at most once per rolling 24h; a created or updated login is a
    /// cache-miss and is checked immediately regardless of that window.
    func check(userId: String,
               candidates: [CompromisedPasswordCandidate]) async throws -> Set<String>
}

public final class CompromisedPasswordChecker: CompromisedPasswordCheckerProtocol, Sendable {
    private let remoteDatasource: any RemoteCompromisedPasswordsDatasourceProtocol
    private let localDatasource: any LocalCompromisedPasswordDatasourceProtocol
    private let scanTracker: any CompromisedPasswordScanTrackerProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let dateProvider: any CurrentDateProviderProtocol
    private let maxConcurrentRequests: Int
    private let logger: Logger

    public init(remoteDatasource: any RemoteCompromisedPasswordsDatasourceProtocol,
                localDatasource: any LocalCompromisedPasswordDatasourceProtocol,
                scanTracker: any CompromisedPasswordScanTrackerProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                logManager: any LogManagerProtocol,
                maxConcurrentRequests: Int = 8,
                dateProvider: any CurrentDateProviderProtocol) {
        self.remoteDatasource = remoteDatasource
        self.localDatasource = localDatasource
        self.scanTracker = scanTracker
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

        let cached = try await loadCachedChecks(userId: userId)

        var currentLastChange: Int?
        if scanTracker.isFullScanDue(userId: userId) {
            do {
                currentLastChange = try await remoteDatasource.getLastChangeTimestamp()
            } catch {
                logger.warning("Failed to fetch last timestamp for compromised password")
                // Same policy as a failed prefix query: serve cached results rather than dropping
                // known breaches, and leave the window open so the next refresh retries
            }
        }

        // Without a fresh corpus timestamp (inside the daily window, or after a failed fetch) the corpus
        // is assumed unchanged; edited logins still miss the cache
        let (cachedBreachCounts, candidatesToQuery) = splitByCacheHit(derivedCandidates,
                                                                      cachedChecks: cached,
                                                                      corpusLastChange: currentLastChange)

        var results = cachedBreachCounts
        if !candidatesToQuery.isEmpty {
            let remoteBreachCounts = await checkRemotely(candidatesToQuery,
                                                         cachedChecks: cached,
                                                         userId: userId)
            results.merge(remoteBreachCounts) { _, new in new }
        }

        // A failed prefix keeps its old `checkedAt`, so the next daily scan re-queries only that prefix, and
        // restarting the window stops it from forcing a rescan every refresh. A cancelled scan restarts
        // nothing: the next refresh rescans and skips the prefixes it already saved.
        if currentLastChange != nil, !Task.isCancelled {
            scanTracker.recordFullScan(userId: userId)
        }

        logger.info("Finished fetching and checking compromised passwords for \(candidates.count) logins")
        return Set(results.filter { $0.value > 0 }.map(\.key))
    }
}

private extension CompromisedPasswordChecker {
    func loadCachedChecks(userId: String) async throws -> [String: CompromisedPasswordCheck] {
        let stored: [CompromisedPasswordCheck]
        do {
            stored = try await localDatasource.getChecks(userId: userId)
        } catch {
            logger.warning("Failed to fetch locally stored items password checks")
            throw error
        }
        // Rows of logins that aren't candidates right now (mid full sync, hidden vault, excluded item)
        // are kept, so those logins aren't queried again when they come back. Logout removes them.
        return Dictionary(stored.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
    }

    func splitByCacheHit(_ candidates: [DerivedCompromisedPasswordCandidate],
                         cachedChecks: [String: CompromisedPasswordCheck],
                         corpusLastChange: Int?)
        -> (cachedBreachCounts: [String: Int], candidatesToQuery: [DerivedCompromisedPasswordCandidate]) {
        var cachedBreachCounts = [String: Int]()
        var candidatesToQuery = [DerivedCompromisedPasswordCandidate]()
        for candidate in candidates {
            if let cachedCheck = cachedChecks[candidate.id],
               cachedCheck.passwordHash == candidate.passwordHash,
               cachedCheck.checkedAt >= corpusLastChange ?? 0 {
                cachedBreachCounts[candidate.id] = cachedCheck.breachCount
            } else {
                candidatesToQuery.append(candidate)
            }
        }
        return (cachedBreachCounts, candidatesToQuery)
    }

    func checkRemotely(_ candidates: [DerivedCompromisedPasswordCandidate],
                       cachedChecks: [String: CompromisedPasswordCheck],
                       userId: String) async -> [String: Int] {
        let checkedAt = Int(dateProvider.getCurrentDate().timeIntervalSince1970)
        let outcomes = await batchProcess(groups: candidates.groupedByPrefix,
                                          cachedChecks: cachedChecks,
                                          checkedAt: checkedAt)

        var breachCounts = [String: Int]()
        var checksToSave = [CompromisedPasswordCheck]()
        for outcome in outcomes {
            breachCounts.merge(outcome.breachCounts) { _, new in new }
            checksToSave.append(contentsOf: outcome.checks)
        }
        do {
            try await localDatasource.upsert(checksToSave, userId: userId)
        } catch {
            logger.warning("Failed to upsert \(checksToSave.count) CompromisedPasswordCheck")
        }
        return breachCounts
    }

    /// Unlike `parallelMap`, cancellation stops scheduling new prefixes but keeps the outcomes already
    /// received, so a cancelled scan still saves what it downloaded instead of starting over.
    func batchProcess(groups: [String: [DerivedCompromisedPasswordCandidate]],
                      cachedChecks: [String: CompromisedPasswordCheck],
                      checkedAt: Int) async -> [PrefixOutcome] {
        let processGroup: @Sendable (String, [DerivedCompromisedPasswordCandidate]) async -> PrefixOutcome = {
            await self.process(prefix: $0, candidates: $1, cachedChecks: cachedChecks, checkedAt: checkedAt)
        }
        return await withTaskGroup(of: PrefixOutcome.self) { group in
            var pendingGroups = groups.makeIterator()
            for _ in 0..<maxConcurrentRequests {
                guard !Task.isCancelled, let (prefix, candidates) = pendingGroups.next() else { break }
                group.addTask { await processGroup(prefix, candidates) }
            }
            var outcomes = [PrefixOutcome]()
            while let outcome = await group.next() {
                outcomes.append(outcome)
                if !Task.isCancelled, let (prefix, candidates) = pendingGroups.next() {
                    group.addTask { await processGroup(prefix, candidates) }
                }
            }
            return outcomes
        }
    }

    func process(prefix: String,
                 candidates: [DerivedCompromisedPasswordCandidate],
                 cachedChecks: [String: CompromisedPasswordCheck],
                 checkedAt: Int) async -> PrefixOutcome {
        // Only reuse a stored ETag (and thus accept a 304) when every item in this prefix has a
        // matching, still-valid cached result to fall back on - otherwise force a fresh body.
        let cachedEtags = Set(candidates.compactMap { cachedChecks[$0.id]?.etag }.filter { !$0.isEmpty })
        let everyCandidateHasValidCache = candidates.allSatisfy { candidate in
            guard let cachedCheck = cachedChecks[candidate.id] else {
                return false
            }
            return cachedCheck.passwordHash == candidate.passwordHash
                && cachedCheck.prefix == prefix
                && !cachedCheck.etag.isEmpty
        }
        let etag = cachedEtags.count == 1 && everyCandidateHasValidCache ? cachedEtags.first : nil
        var breachCounts = [String: Int]()
        var checks = [CompromisedPasswordCheck]()

        do {
            let response = try await remoteDatasource.query(prefix6: prefix, etag: etag)
            switch response {
            case .notModified:
                for candidate in candidates {
                    guard let cachedCheck = cachedChecks[candidate.id] else {
                        continue
                    }
                    breachCounts[candidate.id] = cachedCheck.breachCount
                    checks.append(.init(shareId: candidate.shareId,
                                        itemId: candidate.itemId,
                                        passwordHash: cachedCheck.passwordHash,
                                        prefix: cachedCheck.prefix,
                                        etag: cachedCheck.etag,
                                        breachCount: cachedCheck.breachCount,
                                        checkedAt: checkedAt))
                }
                return .init(breachCounts: breachCounts, checks: checks)

            case let .modified(newEtag, body):
                let breachCountsBySuffix = body.parseBreachRange().countsBySuffix
                for candidate in candidates {
                    let breachCount = breachCountsBySuffix[candidate.suffix] ?? 0
                    breachCounts[candidate.id] = breachCount
                    checks.append(.init(shareId: candidate.shareId,
                                        itemId: candidate.itemId,
                                        passwordHash: candidate.passwordHash,
                                        prefix: prefix,
                                        etag: newEtag ?? "",
                                        breachCount: breachCount,
                                        checkedAt: checkedAt))
                }
                return .init(breachCounts: breachCounts, checks: checks)
            }
        } catch {
            logger.error(error)
            // Keep cached results on error; never invalidate or mark unbreached.
            let cachedBreachCounts = candidates.compactMap { candidate -> (String, Int)? in
                guard let cachedCheck = cachedChecks[candidate.id],
                      cachedCheck.passwordHash == candidate.passwordHash else {
                    return nil
                }
                return (candidate.id, cachedCheck.breachCount)
            }
            return .init(breachCounts: Dictionary(cachedBreachCounts, uniquingKeysWith: { _, new in new }),
                         checks: [])
        }
    }
}

// MARK: - Internal data struct

extension CompromisedPasswordChecker {
    /// The plaintext candidate is deliberately not retained, so the password only lives for the duration
    /// of the initializer.
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
}

private extension [CompromisedPasswordChecker.DerivedCompromisedPasswordCandidate] {
    var groupedByPrefix: [String: Self] {
        Dictionary(grouping: self, by: \.prefix)
    }
}

private extension CompromisedPasswordChecker {
    struct PrefixOutcome {
        /// Breach count keyed by itemId + shareId.
        let breachCounts: [String: Int]
        let checks: [CompromisedPasswordCheck]
    }
}
