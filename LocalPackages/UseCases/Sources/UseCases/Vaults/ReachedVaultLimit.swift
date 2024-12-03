//
//
// ReachedVaultLimit.swift
// Proton Pass - Created on 03/11/2023.
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
//
//
// import Client
//
// public protocol ReachedVaultLimitUseCase: Sendable {
//    func execute() async throws -> Bool
// }
//
// public extension ReachedVaultLimitUseCase {
//    func callAsFunction() async throws -> Bool {
//        try await execute()
//    }
// }
//
// public final class ReachedVaultLimit: ReachedVaultLimitUseCase {
//    private let accessRepository: any AccessRepositoryProtocol
//    private let vaultsManager: any VaultsManagerProtocol
//
//    public init(accessRepository: any AccessRepositoryProtocol,
//                vaultsManager: any VaultsManagerProtocol) {
//        self.accessRepository = accessRepository
//        self.vaultsManager = vaultsManager
//    }
//
//    public func execute() async throws -> Bool {
//        guard let limit = try await accessRepository.getPlan(userId: nil).vaultLimit else {
//            return false
//        }
//
//        return vaultsManager.getAllVaults().count >= limit
//    }
// }
