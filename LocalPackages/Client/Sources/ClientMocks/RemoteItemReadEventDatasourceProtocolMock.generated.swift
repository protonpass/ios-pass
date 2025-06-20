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
import Entities
import Foundation

public final class RemoteItemReadEventDatasourceProtocolMock: @unchecked Sendable, RemoteItemReadEventDatasourceProtocol {

    public init() {}

    // MARK: - send
    public var sendUserIdEventsShareIdThrowableError1: Error?
    public var closureSend: () -> () = {}
    public var invokedSendfunction = false
    public var invokedSendCount = 0
    public var invokedSendParameters: (userId: String, events: [ItemReadEvent], shareId: String)?
    public var invokedSendParametersList = [(userId: String, events: [ItemReadEvent], shareId: String)]()

    public func send(userId: String, events: [ItemReadEvent], shareId: String) async throws {
        invokedSendfunction = true
        invokedSendCount += 1
        invokedSendParameters = (userId, events, shareId)
        invokedSendParametersList.append((userId, events, shareId))
        if let error = sendUserIdEventsShareIdThrowableError1 {
            throw error
        }
        closureSend()
    }
}
