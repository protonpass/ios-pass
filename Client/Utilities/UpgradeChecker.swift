//
// UpgradeChecker.swift
// Proton Pass - Created on 04/05/2023.
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

import Core

public struct AliasLimitation {
    public let count: Int
    public let limit: Int
}

public protocol UpgradeCheckerProtocol: AnyObject {
    var passPlanRepository: PassPlanRepositoryProtocol { get }
    var counter: LimitationCounterProtocol { get }

    /// Return `null` when there's no limitation (unlimited aliases)
    func aliasLimitation() async throws -> AliasLimitation?
    func canCreateMoreVaults() async throws -> Bool
    func canCreateMoreTOTPs() async throws -> Bool
    func isFreeUser() async throws -> Bool
}

public extension UpgradeCheckerProtocol {
    func aliasLimitation() async throws -> AliasLimitation? {
        let plan = try await passPlanRepository.getPlan()
        if let aliasLimit = plan.aliasLimit {
            return .init(count: counter.getAliasCount(), limit: aliasLimit)
        }
        return nil
    }

    func canCreateMoreVaults() async throws -> Bool {
        let plan = try await passPlanRepository.getPlan()
        if let vaultLimit = plan.vaultLimit {
            let vaultCount = counter.getVaultCount()
            return vaultCount < vaultLimit
        }
        return true
    }

    func canCreateMoreTOTPs() async throws -> Bool {
        let plan = try await passPlanRepository.getPlan()
        if let totpLimit = plan.totpLimit {
            let totpCount = counter.getTOTPCount()
            return totpCount < totpLimit
        }
        return true
    }

    func isFreeUser() async throws -> Bool {
        let plan = try await passPlanRepository.getPlan()
        return plan.planType == .free
    }
}

public protocol LimitationCounterProtocol {
    func getAliasCount() -> Int
    func getVaultCount() -> Int
    func getTOTPCount() -> Int
}

public final class UpgradeChecker: UpgradeCheckerProtocol {
    public let passPlanRepository: PassPlanRepositoryProtocol
    public let counter: LimitationCounterProtocol

    public init(passPlanRepository: PassPlanRepositoryProtocol,
                counter: LimitationCounterProtocol) {
        self.passPlanRepository = passPlanRepository
        self.counter = counter
    }
}
