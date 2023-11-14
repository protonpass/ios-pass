//
// UpdateLastUseTime.swift
// Proton Pass - Created on 09/11/2023.
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

import Client
import Core
import Entities
import Foundation

public protocol UpdateLastUseTimeUseCase {
    func execute(baseUrl: String,
                 sessionId: String,
                 accessToken: String,
                 appVersion: String,
                 item: ItemIdentifiable,
                 date: Date) async throws -> UpdateLastUseTimeResult
}

public extension UpdateLastUseTimeUseCase {
    func callAsFunction(baseUrl: String,
                        sessionId: String,
                        accessToken: String,
                        appVersion: String,
                        item: ItemIdentifiable,
                        date: Date) async throws -> UpdateLastUseTimeResult {
        try await execute(baseUrl: baseUrl,
                          sessionId: sessionId,
                          accessToken: accessToken,
                          appVersion: appVersion,
                          item: item,
                          date: date)
    }
}

public final class UpdateLastUseTime: UpdateLastUseTimeUseCase {
    private let apiService: ApiServiceLiteProtocol

    public init(apiService: ApiServiceLiteProtocol) {
        self.apiService = apiService
    }

    public func execute(baseUrl: String,
                        sessionId: String,
                        accessToken: String,
                        appVersion: String,
                        item: ItemIdentifiable,
                        date: Date) async throws -> UpdateLastUseTimeResult {
        let path = "/pass/v1/share/\(item.shareId)/item/\(item.itemId)/lastuse"
        let body = UpdateLastUseTimeRequest(lastUseTime: Int(date.timeIntervalSince1970))
        let request = try URLUtils.makeUrlRequest(baseUrl: baseUrl,
                                                  path: path,
                                                  method: .put,
                                                  appVersion: appVersion,
                                                  sessionId: sessionId,
                                                  accessToken: accessToken,
                                                  body: body)
        let code = try await apiService.execute(request: request)
        return switch code {
        case 401:
            .shouldRefreshAccessToken
        case 400, 402...499:
            .shouldLogOut
        default:
            .successful
        }
    }
}
