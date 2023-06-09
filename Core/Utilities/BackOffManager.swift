//
// BackOffManager.swift
// Proton Pass - Created on 09/06/2023.
// Copyright (c) 2023 Proton Technologies AG
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

/// Keep track of failures and double the wait time when failure occurs
public protocol BackOffManagerProtocol: AnyObject {
    var failureDates: [Date] { get set }
    var currentDateProvider: CurrentDateProviderProtocol { get }

    /// Call this function when failure occurs and we want to back off
    func recordFailure()

    /// Return `true` when no need to back off, internally reset state
    /// Return `false` when back-off is still needed
    func canProceed() -> Bool
}

public extension BackOffManagerProtocol {
    func recordFailure() {
        failureDates.append(currentDateProvider.getCurrentDate())
    }

    func canProceed() -> Bool {
        guard let mostRecentFailureDate = failureDates.last else { return true }
        let stride = BackOffStride.stride(failureCount: failureDates.count)
        let thresholdDate = mostRecentFailureDate.adding(component: .second,
                                                         value: stride.valueInSeconds.toInt)
        let currentDate = currentDateProvider.getCurrentDate()
        let canProceed = currentDate >= thresholdDate
        if canProceed {
            failureDates.removeAll()
        }
        return canProceed
    }
}

public final class BackOffManager: BackOffManagerProtocol {
    public var failureDates: [Date]
    public let currentDateProvider: CurrentDateProviderProtocol

    public init(currentDateProvider: CurrentDateProviderProtocol) {
        self.failureDates = []
        self.currentDateProvider = currentDateProvider
    }
}

enum BackOffStride: CaseIterable {
    case zeroSecond
    case oneSecond, twoSeconds, fiveSeconds, tenSeconds, thirtySeconds
    case oneMinute, twoMinutes, fiveMinutes, tenMinutes, thirtyMinutes

    var valueInSeconds: Double {
        switch self {
        case .zeroSecond:
            return 0
        case .oneSecond:
            return 1
        case .twoSeconds:
            return 2
        case .fiveSeconds:
            return 5
        case .tenSeconds:
            return 10
        case .thirtySeconds:
            return 30
        case .oneMinute:
            return 60
        case .twoMinutes:
            return 2 * 60
        case .fiveMinutes:
            return 5 * 60
        case .tenMinutes:
            return 10 * 60
        case .thirtyMinutes:
            return 30 * 60
        }
    }

    static func stride(failureCount: Int) -> BackOffStride {
        guard failureCount > 0 else { return .zeroSecond }
        if failureCount >= BackOffStride.allCases.count {
            return BackOffStride.allCases.last ?? .thirtyMinutes
        } else {
            return BackOffStride.allCases[safeIndex: failureCount] ?? .zeroSecond
        }
    }
}
