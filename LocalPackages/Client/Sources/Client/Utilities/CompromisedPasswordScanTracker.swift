//
// CompromisedPasswordScanTracker.swift
// Proton Pass - Created on 30/09/2026.
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
import Foundation

// sourcery: AutoMockable
public protocol CompromisedPasswordScanTrackerProtocol: Sendable {
    func isFullScanDue(userId: String) -> Bool
    func isCorpusUnchanged(userId: String, currentLastChange: Int) -> Bool
    func recordFullScan(userId: String)
    func recordCorpusLastChange(_ lastChange: Int, userId: String)
}

public final class CompromisedPasswordScanTracker: CompromisedPasswordScanTrackerProtocol {
    private let localTimestampDatasource: any LocalTimestampDatasourceProtocol
    private let dateProvider: any CurrentDateProviderProtocol

    public init(localTimestampDatasource: any LocalTimestampDatasourceProtocol,
                dateProvider: any CurrentDateProviderProtocol) {
        self.localTimestampDatasource = localTimestampDatasource
        self.dateProvider = dateProvider
    }
}

public extension CompromisedPasswordScanTracker {
    func isFullScanDue(userId: String) -> Bool {
        let key = Constants.CompromisedPasswords.lastRunKey(userId)
        guard let lastRun = localTimestampDatasource.getTimestamp(key: key) else {
            return true
        }
        let elapsed = now - lastRun
        guard elapsed >= 0 else { return true }
        return elapsed >= Constants.CompromisedPasswords.minimumCheckInterval
    }

    func isCorpusUnchanged(userId: String, currentLastChange: Int) -> Bool {
        let key = Constants.CompromisedPasswords.lastCorpusChangeKey(userId)
        guard let stored = localTimestampDatasource.getTimestamp(key: key) else {
            return false
        }
        return currentLastChange <= stored
    }

    func recordFullScan(userId: String) {
        let key = Constants.CompromisedPasswords.lastRunKey(userId)
        localTimestampDatasource.setTimestamp(now, key: key)
    }

    func recordCorpusLastChange(_ lastChange: Int, userId: String) {
        let key = Constants.CompromisedPasswords.lastCorpusChangeKey(userId)
        localTimestampDatasource.setTimestamp(lastChange, key: key)
    }
}

private extension CompromisedPasswordScanTracker {
    var now: Int {
        Int(dateProvider.getCurrentDate().timeIntervalSince1970)
    }
}
