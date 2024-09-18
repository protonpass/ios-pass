//
// ShouldDisplayUpgradeAppBanner.swift
// Proton Pass - Created on 05/03/2024.
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

import Client
import Core
import Foundation

public protocol ShouldDisplayUpgradeAppBannerUseCase: Sendable {
    func execute() async throws -> Bool
}

public extension ShouldDisplayUpgradeAppBannerUseCase {
    func callAsFunction() async throws -> Bool {
        try await execute()
    }
}

public final class ShouldDisplayUpgradeAppBanner: ShouldDisplayUpgradeAppBannerUseCase {
    private let accessRepository: any AccessRepositoryProtocol
    private let bundle: Bundle
    private let userDefaults: UserDefaults

    public init(accessRepository: any AccessRepositoryProtocol,
                bundle: Bundle,
                userDefaults: UserDefaults) {
        self.accessRepository = accessRepository
        self.bundle = bundle
        self.userDefaults = userDefaults
    }

    public func execute() async throws -> Bool {
        let access = try await accessRepository.refreshAccess(userId: nil)
        if bundle.isQaBuild, userDefaults.bool(forKey: Constants.QA.forceDisplayUpgradeAppBanner) {
            return true
        }
        return access.access.minVersionUpgrade != nil
    }
}
