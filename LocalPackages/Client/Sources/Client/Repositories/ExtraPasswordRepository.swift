//
// ExtraPasswordRepository.swift
// Proton Pass - Created on 05/06/2024.
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

import Entities
import Foundation
@preconcurrency import ProtonCoreServices

public protocol ExtraPasswordRepositoryProtocol: Sendable {
    func getModulus(userId: String) async throws -> Modulus
    func enableExtraPassword(userId: String, userSrp: PassUserSrp) async throws
    func disableExtraPassword(userId: String) async throws
    func initiateSrpAuthentication(userId: String) async throws -> SrpAuthenticationData
    func validateSrpAuthentication(userId: String, data: SrpValidationData) async throws
}

public final class ExtraPasswordRepository: Sendable, ExtraPasswordRepositoryProtocol {
    private let apiServicing: any APIManagerProtocol

    public init(apiServicing: some APIManagerProtocol) {
        self.apiServicing = apiServicing
    }
}

public extension ExtraPasswordRepository {
    func getModulus(userId: String) async throws -> Modulus {
        let endpoint = GetModulusEndpoint()
        let response = try await apiServicing.getApiService(userId: userId).exec(endpoint: endpoint)
        return response
    }

    func enableExtraPassword(userId: String, userSrp: PassUserSrp) async throws {
        let endpoint = EnableExtraPasswordEndpoint(userSrp)
        _ = try await apiServicing.getApiService(userId: userId).exec(endpoint: endpoint)
    }

    func disableExtraPassword(userId: String) async throws {
        let endpoint = DisableExtraPasswordEndpoint()
        _ = try await apiServicing.getApiService(userId: userId).exec(endpoint: endpoint)
    }

    func initiateSrpAuthentication(userId: String) async throws -> SrpAuthenticationData {
        let endpoint = InitiateSrpAuthenticationEndpoint()
        let response = try await apiServicing.getApiService(userId: userId).exec(endpoint: endpoint)
        return response.srpData
    }

    func validateSrpAuthentication(userId: String, data: SrpValidationData) async throws {
        let endpoint = ValidateSrpAuthenticationEndpoint(data)
        _ = try await apiServicing.getApiService(userId: userId).exec(endpoint: endpoint)
    }
}
