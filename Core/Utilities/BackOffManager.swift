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

    func canProceed() -> Bool { false }
}

public final class BackOffManager: BackOffManagerProtocol {
    public var failureDates: [Date]
    public let currentDateProvider: CurrentDateProviderProtocol

    public init(currentDateProvider: CurrentDateProviderProtocol) {
        self.failureDates = []
        self.currentDateProvider = currentDateProvider
    }
}
