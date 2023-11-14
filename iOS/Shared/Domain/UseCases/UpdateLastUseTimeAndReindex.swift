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

import AuthenticationServices
import Client
import Core
import Entities
import Foundation
import UseCases

protocol UpdateLastUseTimeAndReindexUseCase {
    func execute(item: ItemContent,
                 date: Date,
                 identifiers: [ASCredentialServiceIdentifier]) async throws
}

extension UpdateLastUseTimeAndReindexUseCase {
    func callAsFunction(item: ItemContent,
                        date: Date,
                        identifiers: [ASCredentialServiceIdentifier]) async throws {
        try await execute(item: item, date: date, identifiers: identifiers)
    }
}

final class UpdateLastUseTimeAndReindex: UpdateLastUseTimeAndReindexUseCase {
    private let updateLastUseTime: UpdateLastUseTimeUseCase
    private let reindexLoginItem: ReindexLoginItemUseCase
    private let wipeAllData: WipeAllDataUseCase
    private let logger: Logger

    init(updateLastUseTime: UpdateLastUseTimeUseCase,
         reindexLoginItem: ReindexLoginItemUseCase,
         wipeAllData: WipeAllDataUseCase,
         logManager: LogManagerProtocol) {
        self.updateLastUseTime = updateLastUseTime
        self.reindexLoginItem = reindexLoginItem
        self.wipeAllData = wipeAllData
        logger = .init(manager: logManager)
    }

    public func execute(item: ItemContent,
                        date: Date,
                        identifiers: [ASCredentialServiceIdentifier]) async throws {
        do {
            try await updateLastUseTime(item: item, date: date)
            try await reindexLoginItem(item: item, identifiers: identifiers, lastUseTime: date)
        } catch {
            logger.error(error)
        }
    }
}
