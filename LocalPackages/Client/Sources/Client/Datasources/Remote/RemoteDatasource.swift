//
// RemoteDatasource.swift
// Proton Pass - Created on 16/08/2022.
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

import Foundation
import ProtonCoreNetworking
import ProtonCoreServices

public let kDefaultPageSize = 100

public class RemoteDatasource {
    private let apiService: APIService
    private let eventStream: CorruptedSessionEventStream

    public init(apiService: APIService, eventStream: CorruptedSessionEventStream) {
        self.apiService = apiService
        self.eventStream = eventStream
    }

    public func exec<E: Endpoint>(endpoint: E) async throws -> E.Response {
        do {
            return try await apiService.exec(endpoint: endpoint)
        } catch {
            throw streamAndReturn(error: error)
        }
    }

    public func exec<E: Endpoint>(endpoint: E, files: [String: URL]) async throws -> E.Response {
        do {
            return try await apiService.exec(endpoint: endpoint, files: files)
        } catch {
            throw streamAndReturn(error: error)
        }
    }

    public func execExpectingData(endpoint: some Endpoint) async throws -> DataResponse {
        do {
            return try await apiService.execExpectingData(endpoint: endpoint)
        } catch {
            throw streamAndReturn(error: error)
        }
    }
}

private extension RemoteDatasource {
    /// Stream the error if session is corrupted and return the error as-is to continue the throwing flow as normal
    func streamAndReturn(error: Error) -> Error {
        if let responseError = error as? ResponseError,
           let httpCode = responseError.httpCode {
            let sessionId = apiService.sessionUID
            switch httpCode {
            case 403:
                eventStream.send(.unauthSessionMakingAuthRequests(sessionId))
            default:
                break
            }
        }
        return error
    }
}
