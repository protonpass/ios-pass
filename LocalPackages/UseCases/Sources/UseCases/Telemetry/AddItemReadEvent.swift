//
// AddItemReadEvent.swift
// Proton Pass - Created on 11/06/2024.
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

import Client
import Core
import Entities
import Foundation

public protocol AddItemReadEventUseCase: Sendable {
    func execute(_ item: any ItemIdentifiable)
}

public extension AddItemReadEventUseCase {
    func callAsFunction(_ item: any ItemIdentifiable) {
        execute(item)
    }
}

public final class AddItemReadEvent: Sendable, AddItemReadEventUseCase {
    private let eventRepository: any ItemReadEventRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let userManager: any UserManagerProtocol
    private let logger: Logger

    public init(eventRepository: any ItemReadEventRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.eventRepository = eventRepository
        self.accessRepository = accessRepository
        self.userManager = userManager
        logger = .init(manager: logManager)
    }

    public func execute(_ item: any ItemIdentifiable) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                if accessRepository.access.value?.access.plan.isBusinessUser == true {
                    try await eventRepository.addEvent(userId: userId, item: item)
                }
            } catch {
                logger.error(error)
            }
        }
    }
}
