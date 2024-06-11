//
// ItemReadEventRepository.swift
// Proton Pass - Created on 10/06/2024.
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

import Core
import Entities
import Foundation

public protocol ItemReadEventRepositoryProtocol: Sendable {
    func addEvent(for item: any ItemIdentifiable) async throws
    func sendAllEvents() async throws
}

public actor ItemReadEventRepository: ItemReadEventRepositoryProtocol {
    private let localDatasource: any LocalItemReadEventDatasourceProtocol
    private let remoteDatasource: any RemoteItemReadEventDatasourceProtocol
    private let userDataProvider: any UserDataProvider
    private let eventCount: Int
    private let logger: Logger

    public init(localDatasource: any LocalItemReadEventDatasourceProtocol,
                remoteDatasource: any RemoteItemReadEventDatasourceProtocol,
                userDataProvider: any UserDataProvider,
                logManager: any LogManagerProtocol,
                eventCount: Int = Constants.Utils.batchSize) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.userDataProvider = userDataProvider
        logger = .init(manager: logManager)
        self.eventCount = eventCount
    }
}

public extension ItemReadEventRepository {
    func addEvent(for item: any ItemIdentifiable) async throws {
        let userId = try userDataProvider.getUserId()
//        try await localDatasource.insertEvent(item, userId: userId)
    }

    func sendAllEvents() async throws {}
}
