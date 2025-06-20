// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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

import Client
import Core
import Entities
import Foundation

public final class ItemReadEventRepositoryProtocolMock: @unchecked Sendable, ItemReadEventRepositoryProtocol {

    public init() {}

    // MARK: - addEvent
    public var addEventUserIdItemThrowableError1: Error?
    public var closureAddEvent: () -> () = {}
    public var invokedAddEventfunction = false
    public var invokedAddEventCount = 0
    public var invokedAddEventParameters: (userId: String, item: any ItemIdentifiable)?
    public var invokedAddEventParametersList = [(userId: String, item: any ItemIdentifiable)]()

    public func addEvent(userId: String, item: any ItemIdentifiable) async throws {
        invokedAddEventfunction = true
        invokedAddEventCount += 1
        invokedAddEventParameters = (userId, item)
        invokedAddEventParametersList.append((userId, item))
        if let error = addEventUserIdItemThrowableError1 {
            throw error
        }
        closureAddEvent()
    }
    // MARK: - getAllEvents
    public var getAllEventsUserIdThrowableError2: Error?
    public var closureGetAllEvents: () -> () = {}
    public var invokedGetAllEventsfunction = false
    public var invokedGetAllEventsCount = 0
    public var invokedGetAllEventsParameters: (userId: String, Void)?
    public var invokedGetAllEventsParametersList = [(userId: String, Void)]()
    public var stubbedGetAllEventsResult: [ItemReadEvent]!

    public func getAllEvents(userId: String) async throws -> [ItemReadEvent] {
        invokedGetAllEventsfunction = true
        invokedGetAllEventsCount += 1
        invokedGetAllEventsParameters = (userId, ())
        invokedGetAllEventsParametersList.append((userId, ()))
        if let error = getAllEventsUserIdThrowableError2 {
            throw error
        }
        closureGetAllEvents()
        return stubbedGetAllEventsResult
    }
    // MARK: - sendAllEvents
    public var sendAllEventsUserIdThrowableError3: Error?
    public var closureSendAllEvents: () -> () = {}
    public var invokedSendAllEventsfunction = false
    public var invokedSendAllEventsCount = 0
    public var invokedSendAllEventsParameters: (userId: String, Void)?
    public var invokedSendAllEventsParametersList = [(userId: String, Void)]()

    public func sendAllEvents(userId: String) async throws {
        invokedSendAllEventsfunction = true
        invokedSendAllEventsCount += 1
        invokedSendAllEventsParameters = (userId, ())
        invokedSendAllEventsParametersList.append((userId, ()))
        if let error = sendAllEventsUserIdThrowableError3 {
            throw error
        }
        closureSendAllEvents()
    }
}
