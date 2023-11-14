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

@preconcurrency import ProtonCoreDoh

public protocol UpdateLastUseTimeUseCase: Sendable {
    func execute(item: ItemIdentifiable, date: Date) async throws -> UpdateLastUseTimeResult
}

public extension UpdateLastUseTimeUseCase {
    func callAsFunction(item: ItemIdentifiable, date: Date) async throws -> UpdateLastUseTimeResult {
        try await execute(item: item, date: date)
    }
}

public final class UpdateLastUseTime: UpdateLastUseTimeUseCase {
    private let apiService: ApiServiceLiteProtocol
    private let userDataProvider: UserDataProvider
    private let serverConfig: ServerConfig
    private let appVersion: String

    public init(apiService: ApiServiceLiteProtocol,
                userDataProvider: UserDataProvider,
                serverConfig: ServerConfig,
                appVersion: String) {
        self.apiService = apiService
        self.userDataProvider = userDataProvider
        self.serverConfig = serverConfig
        self.appVersion = appVersion
    }

    public func execute(item: ItemIdentifiable, date: Date) async throws -> UpdateLastUseTimeResult {
        let credential = try userDataProvider.getUnwrappedUserData().credential
        let baseUrl = serverConfig.defaultHost + serverConfig.defaultPath
        let path = "/pass/v1/share/\(item.shareId)/item/\(item.itemId)/lastuse"
        let body = UpdateLastUseTimeRequest(lastUseTime: Int(date.timeIntervalSince1970))
        let request = try URLUtils.makeUrlRequest(baseUrl: baseUrl,
                                                  path: path,
                                                  method: .put,
                                                  appVersion: appVersion,
                                                  sessionId: credential.sessionID,
                                                  accessToken: credential.accessToken,
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
