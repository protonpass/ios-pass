//
// RemoteFavIconDatasource.swift
// Proton Pass - Created on 14/04/2023.
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
import Foundation

public enum FavIconFetchResult: Sendable {
    case positive(Data)
    case negative(FavIconNegativityReason)
}

/// Reason why a fav icon is null
public enum FavIconNegativityReason: Sendable {
    /// Everything is ok, the image simply does not exist
    case notExist

    /// Domain error
    case error(FavIconError)
}

/// Known domain errors
public enum FavIconError: Int, CaseIterable, Sendable {
    case notTrusted = 2_011
    case invalidAddress = -1
    case failedToFindForAppropriateSize = 2_511
    case failedToFind = 2_902
}

public protocol RemoteFavIconDatasourceProtocol: Sendable {
    func fetchFavIcon(userId: String, for domain: String) async throws -> FavIconFetchResult
}

public final class RemoteFavIconDatasource: RemoteDatasource, RemoteFavIconDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteFavIconDatasource {
    func fetchFavIcon(userId: String, for domain: String) async throws -> FavIconFetchResult {
        let endpoint = GetLogoEndpoint(domain: domain)
        let response = try await execExpectingData(userId: userId, endpoint: endpoint)
        return try handle(dataResponse: response)
    }

    func handle(dataResponse: DataResponse) throws -> FavIconFetchResult {
        switch dataResponse.httpCode {
        case 200, 204:
            if let data = dataResponse.data {
                return .positive(data)
            } else {
                return .negative(.notExist)
            }

        default:
            if let protonCode = dataResponse.protonCode,
               let favIconError = FavIconError(rawValue: protonCode) {
                return .negative(.error(favIconError))
            }
            throw PassError.network(.unexpectedHttpStatusCode(dataResponse.httpCode))
        }
    }
}
