//
// SetUpBeforeLaunching.swift
// Proton Pass - Created on 03/07/2024.
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
import Foundation

public protocol SetUpBeforeLaunchingUseCase: Sendable {
    func execute() async throws
}

public extension SetUpBeforeLaunchingUseCase {
    func callAsFunction() async throws {
        try await execute()
    }
}

public final class SetUpBeforeLaunching: SetUpBeforeLaunchingUseCase {
    private let userManager: any UserManagerProtocol
    private let prefererencesManager: any PreferencesManagerProtocol
    private let applyMigration: any ApplyAppMigrationUseCase

    public init(userManager: any UserManagerProtocol,
                prefererencesManager: any PreferencesManagerProtocol,
                applyMigration: any ApplyAppMigrationUseCase) {
        self.userManager = userManager
        self.prefererencesManager = prefererencesManager
        self.applyMigration = applyMigration
    }

    /// Order matters, `UserManager` needs to be set up before `PrefererencesManager`
    /// because `PrefererencesManager` depends on `UserManager`
    public func execute() async throws {
        try await userManager.setUp()
        try await prefererencesManager.setUp()
        try await applyMigration()
    }
}
