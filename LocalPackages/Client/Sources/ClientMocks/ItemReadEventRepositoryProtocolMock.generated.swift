// Generated using Sourcery 2.2.3 — https://github.com/krzysztofzablocki/Sourcery
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
    public var addEventForThrowableError1: Error?
    public var closureAddEvent: () -> () = {}
    public var invokedAddEventfunction = false
    public var invokedAddEventCount = 0
    public var invokedAddEventParameters: (item: any ItemIdentifiable, Void)?
    public var invokedAddEventParametersList = [(item: any ItemIdentifiable, Void)]()

    public func addEvent(for item: any ItemIdentifiable) async throws {
        invokedAddEventfunction = true
        invokedAddEventCount += 1
        invokedAddEventParameters = (item, ())
        invokedAddEventParametersList.append((item, ()))
        if let error = addEventForThrowableError1 {
            throw error
        }
        closureAddEvent()
    }
    // MARK: - sendAllEvents
    public var sendAllEventsThrowableError2: Error?
    public var closureSendAllEvents: () -> () = {}
    public var invokedSendAllEventsfunction = false
    public var invokedSendAllEventsCount = 0

    public func sendAllEvents() async throws {
        invokedSendAllEventsfunction = true
        invokedSendAllEventsCount += 1
        if let error = sendAllEventsThrowableError2 {
            throw error
        }
        closureSendAllEvents()
    }
}
