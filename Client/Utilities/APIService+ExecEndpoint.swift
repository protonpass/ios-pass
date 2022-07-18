//
// APIService+ExecEndpoint.swift
// Proton Pass - Created on 12/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import Combine
import ProtonCore_Networking
import ProtonCore_Services

public extension APIService {
    /// Async variant that can take an `Endpoint`
    func exec<E: Endpoint>(endpoint: E) async throws -> E.Response {
        try await withCheckedThrowingContinuation { continuation in
            exec(route: endpoint) { (_, result: Result<E.Response, ResponseError>) in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let data):
                    continuation.resume(returning: data)
                }
            }
        }
    }
}
