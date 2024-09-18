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

import Entities

public struct AliasLimitation: Sendable {
    public let count: Int
    public let limit: Int
}

public protocol UpgradeCheckerProtocol: AnyObject, Sendable {
    /// Return `null` when there's no limitation (unlimited aliases)
    func aliasLimitation() async throws -> AliasLimitation?
    func canCreateMoreVaults() async throws -> Bool
    func canHaveMoreLoginsWith2FA() async throws -> Bool
    func canShowTOTPToken(creationDate: Int64) async throws -> Bool
    func isFreeUser() async throws -> Bool
}

public final class UpgradeChecker: UpgradeCheckerProtocol {
    private let accessRepository: any AccessRepositoryProtocol
    private let counter: any LimitationCounterProtocol
    private let totpChecker: any TOTPCheckerProtocol

    public init(accessRepository: any AccessRepositoryProtocol,
                counter: any LimitationCounterProtocol,
                totpChecker: any TOTPCheckerProtocol) {
        self.accessRepository = accessRepository
        self.counter = counter
        self.totpChecker = totpChecker
    }
}

public extension UpgradeChecker {
    func aliasLimitation() async throws -> AliasLimitation? {
        let plan = try await accessRepository.getPlan(userId: nil)
        if let aliasLimit = plan.aliasLimit {
            return .init(count: counter.getAliasCount(), limit: aliasLimit)
        }
        return nil
    }

    func canCreateMoreVaults() async throws -> Bool {
        let plan = try await accessRepository.getPlan(userId: nil)
        if let vaultLimit = plan.vaultLimit {
            let vaultCount = counter.getVaultCount()
            return vaultCount < vaultLimit
        }
        return true
    }

    func canHaveMoreLoginsWith2FA() async throws -> Bool {
        let plan = try await accessRepository.getPlan(userId: nil)
        guard let totpLimit = plan.totpLimit else { return true }
        return counter.getTOTPCount() < totpLimit
    }

    func canShowTOTPToken(creationDate: Int64) async throws -> Bool {
        let plan = try await accessRepository.getPlan(userId: nil)
        guard let totpLimit = plan.totpLimit else { return true }

        if let threshold = try await totpChecker.totpCreationDateThreshold(numberOfTotp: totpLimit) {
            return creationDate <= threshold
        }
        return true
    }

    func isFreeUser() async throws -> Bool {
        let plan = try await accessRepository.getPlan(userId: nil)
        return plan.isFreeUser
    }
}

public protocol LimitationCounterProtocol: AnyObject, Sendable {
    func getAliasCount() -> Int
    func getVaultCount() -> Int
    func getTOTPCount() -> Int
}

public protocol TOTPCheckerProtocol: Sendable {
    /// Get the maximum creation date of items that are allowed to display 2FA token
    /// If the creation date of a given login is less than this max creation date, we don't calculate the 2FA token
    func totpCreationDateThreshold(numberOfTotp: Int) async throws -> Int64?
}
