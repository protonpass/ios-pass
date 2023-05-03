//
// UserPlanManager.swift
// Proton Pass - Created on 03/05/2023.
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

import Foundation

public protocol UserPlanManagerProtocol: AnyObject {
    func canCreateMoreVaults() async throws -> Bool
    func canCreateMoreTOTPs() async throws -> Bool
    func isFreeUser() async throws -> Bool
}

public extension UserPlanManagerProtocol {
    func canCreateMoreVaults() async throws -> Bool {
        #if DEBUG
        return .random()
        #else
        return true
        #endif
    }

    func canCreateMoreTOTPs() async throws -> Bool {
        #if DEBUG
        return .random()
        #else
        return true
        #endif
    }

    func isFreeUser() async throws -> Bool {
        #if DEBUG
        return .random()
        #else
        return false
        #endif
    }
}

public final class UserPlanManager: UserPlanManagerProtocol {
    public init() {}
}
