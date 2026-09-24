//
// FullSyncOperation.swift
// Proton Pass - Created on 23/09/2026.
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

import Foundation
import Observation

public enum FullSyncPresentation: Sendable {
    /// Non-dismissible progress sheet
    case sheet
    /// Progress embedded in the items tab after logging in
    case inline
}

/// State of one full sync for one user. Observers read the state instead of listening to events,
/// so they can start observing at any time, even after the sync has finished.
@MainActor
@Observable
public final class FullSyncOperation: Identifiable {
    public enum Outcome: Sendable {
        case completed(hasUndecryptableShares: Bool)
        case failed(any Error)
        case cancelled

        public var succeeded: Bool {
            if case .completed = self {
                return true
            }
            return false
        }
    }

    public let id = UUID()
    public let userId: String
    public let presentation: FullSyncPresentation
    public private(set) var progresses: [VaultSyncProgress] = []
    /// `nil` while the sync is queued or running
    public private(set) var outcome: Outcome?
    /// Bumped on every progress update and sync step, lets a watchdog tell a slow sync from a stalled one
    @ObservationIgnored public private(set) var activity = 0
    @ObservationIgnored private var waiters: [CheckedContinuation<Outcome, Never>] = []

    public init(userId: String, presentation: FullSyncPresentation) {
        self.userId = userId
        self.presentation = presentation
    }

    /// Returns immediately when the sync has already finished.
    /// Not cancellable: a cancelled caller still waits for the outcome.
    public func result() async -> Outcome {
        if let outcome {
            return outcome
        }
        return await withCheckedContinuation { waiters.append($0) }
    }

    public func updateProgresses(_ progresses: [VaultSyncProgress]) {
        guard outcome == nil else { return }
        self.progresses = progresses
        recordActivity()
    }

    public func recordActivity() {
        activity += 1
    }

    public func finish(_ outcome: Outcome) {
        guard self.outcome == nil else { return }
        self.outcome = outcome
        let pending = waiters
        waiters.removeAll()
        for waiter in pending {
            waiter.resume(returning: outcome)
        }
    }
}
