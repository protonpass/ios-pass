//
// UserManagerFailureReason.swift
// Proton Pass - Created on 16/05/2024.
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

import Foundation

public extension PassError {
    enum UserManagerFailureReason: CustomDebugStringConvertible, LocalizedError, Equatable {
        case userDatasAvailableButNoActiveUserId
        case activeUserIdAvailableButNoUserDataFound
        case activeUserDataNotFound
        case noUserDataFound
        case noInactiveUserFound
        case noAccessFound(String)

        public var debugDescription: String {
            switch self {
            case .userDatasAvailableButNoActiveUserId:
                "User datas available but not active user ID"
            case .activeUserIdAvailableButNoUserDataFound:
                "Active user ID available but no user data found"
            case .activeUserDataNotFound:
                "Active user data not found"
            case .noUserDataFound:
                "No user data found"
            case .noInactiveUserFound:
                "No inactivate user found"
            case let .noAccessFound(userId):
                "No access found for user \(userId)"
            }
        }
    }
}
