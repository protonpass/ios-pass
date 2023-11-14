//
// UpdateLastUseTimeAndReindex.swift
// Proton Pass - Created on 14/11/2023.
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

#if canImport(AuthenticationServices)
import AuthenticationServices
import Client
import Core
import Entities
import Foundation

public protocol UpdateLastUseTimeAndReindexUseCase {
    func execute(item: ItemContent,
                 date: Date,
                 identifiers: [ASCredentialServiceIdentifier]) async throws
}

public extension UpdateLastUseTimeAndReindexUseCase {
    func callAsFunction(item: ItemContent,
                        date: Date,
                        identifiers: [ASCredentialServiceIdentifier]) async throws {
        try await execute(item: item, date: date, identifiers: identifiers)
    }
}

public final class UpdateLastUseTimeAndReindex: UpdateLastUseTimeAndReindexUseCase {
    private let updateLastUseTime: UpdateLastUseTimeUseCase
    private let reindexLoginItem: ReindexLoginItemUseCase
    private let unindexAllLoginItems: UnindexAllLoginItemsUseCase
    private let databaseService: DatabaseServiceProtocol
    private let userDataProvider: UserDataProvider
    private let logger: Logger

    public init(updateLastUseTime: UpdateLastUseTimeUseCase,
                reindexLoginItem: ReindexLoginItemUseCase,
                unindexAllLoginItems: UnindexAllLoginItemsUseCase,
                databaseService: DatabaseServiceProtocol,
                userDataProvider: UserDataProvider,
                logManager: LogManagerProtocol) {
        self.updateLastUseTime = updateLastUseTime
        self.reindexLoginItem = reindexLoginItem
        self.unindexAllLoginItems = unindexAllLoginItems
        self.databaseService = databaseService
        self.userDataProvider = userDataProvider
        logger = .init(manager: logManager)
    }

    public func execute(item: ItemContent,
                        date: Date,
                        identifiers: [ASCredentialServiceIdentifier]) async throws {
        do {
            let result = try await updateLastUseTime(item: item, date: date)
            switch result {
            case .successful:
                logger.info("Updated lastUseTime \(item.debugDescription)")
                try await reindexLoginItem(item: item,
                                           identifiers: identifiers,
                                           lastUseTime: date)
            case .shouldRefreshAccessToken:
                logger.info("TODO: refresh access token")
            case .shouldLogOut:
                logger
                    .error("Token is expired while updating lastUseTime \(item.debugDescription). Logging out.")
                userDataProvider.setUserData(nil)
                databaseService.resetContainer()
                try await unindexAllLoginItems()
            }
        } catch {
            logger.error(error)
        }
    }
}

#endif
