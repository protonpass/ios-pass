//
// SendErrorToSentry.swift
// Proton Pass - Created on 14/12/2023.
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
import Foundation
import Sentry

public protocol SendErrorToSentryUseCase: Sendable {
    func execute(_ error: any Error, sessionId: String?)
}

public extension SendErrorToSentryUseCase {
    func callAsFunction(_ error: any Error, sessionId: String?) {
        execute(error, sessionId: sessionId)
    }
}

public final class SendErrorToSentry: SendErrorToSentryUseCase {
    private let userDataProvider: any UserDataProvider

    public init(userDataProvider: any UserDataProvider) {
        self.userDataProvider = userDataProvider
    }

    public func execute(_ error: any Error, sessionId: String?) {
        let userId = userDataProvider.getUserData()?.user.ID
        SentrySDK.capture(error: error) { scope in
            if let sessionId {
                scope.setTag(value: sessionId, key: "sessionUID")
            }
            if let userId {
                scope.setTag(value: userId, key: "userID")
            }
        }
    }
}
