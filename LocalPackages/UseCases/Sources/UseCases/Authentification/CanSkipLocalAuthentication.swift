//
// CanSkipLocalAuthentication.swift
// Proton Pass - Created on 15/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

import Core
import Entities
import Foundation

public protocol CanSkipLocalAuthenticationUseCase: Sendable {
    func execute(appLockTime: AppLockTime, lastActiveTimestamp: TimeInterval?) -> Bool
}

public extension CanSkipLocalAuthenticationUseCase {
    func callAsFunction(appLockTime: AppLockTime, lastActiveTimestamp: TimeInterval?) -> Bool {
        execute(appLockTime: appLockTime, lastActiveTimestamp: lastActiveTimestamp)
    }
}

public final class CanSkipLocalAuthentication: CanSkipLocalAuthenticationUseCase {
    private let currentDateProvider: any CurrentDateProviderProtocol

    public init(currentDateProvider: any CurrentDateProviderProtocol) {
        self.currentDateProvider = currentDateProvider
    }

    public func execute(appLockTime: AppLockTime,
                        lastActiveTimestamp: TimeInterval?) -> Bool {
        guard let lastActiveTimestamp else {
            return false
        }
        let currentDate = currentDateProvider.getCurrentDate()
        let threshold = TimeInterval(appLockTime.intervalInMinutes * 60)
        return (currentDate.timeIntervalSince1970 - lastActiveTimestamp) <= threshold
    }
}
