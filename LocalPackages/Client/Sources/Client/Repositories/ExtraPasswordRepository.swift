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
    func getModulus() async throws -> Modulus
    func enableExtraPassword(_ userSrp: PassUserSrp) async throws
}

public final class ExtraPasswordRepository: Sendable, ExtraPasswordRepositoryProtocol {
    private let apiService: any APIService

    public init(apiService: any APIService) {
        self.apiService = apiService
    }
}

public extension ExtraPasswordRepository {
    func getModulus() async throws -> Modulus {
        let endpoint = GetModulusEndpoint()
        let response = try await apiService.exec(endpoint: endpoint)
        return response
    }

    func enableExtraPassword(_ userSrp: PassUserSrp) async throws {
        let endpoint = EnableExtraPasswordEndpoint(userSrp)
        _ = try await apiService.exec(endpoint: endpoint)
    }
}
