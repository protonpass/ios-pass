//
// SendMessageToSentry.swift
// Proton Pass - Created on 25/07/2024.
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
import Foundation
import Sentry

public protocol SendMessageToSentryUseCase: Sendable {
    func execute(_ message: String, userId: String, sessionId: String?)
}

public extension SendMessageToSentryUseCase {
    func callAsFunction(_ message: String, userId: String, sessionId: String?) {
        execute(message, userId: userId, sessionId: sessionId)
    }
}

public final class SendMessageToSentry: SendMessageToSentryUseCase {
    public init() {}

    public func execute(_ message: String, userId: String, sessionId: String?) {
        SentrySDK.capture(message: message) { scope in
            if let sessionId {
                scope.setTag(value: sessionId, key: Constants.Sentry.sessionId)
            }
            scope.setTag(value: userId, key: Constants.Sentry.userId)
        }
    }
}
