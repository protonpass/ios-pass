//
//
// ToggleSentinel.swift
// Proton Pass - Created on 23/01/2024.
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

public protocol ToggleSentinelUseCase: Sendable {
    func execute(for id: String) async throws
}

public extension ToggleSentinelUseCase {
    func callAsFunction(for id: String) async throws {
        try await execute(for: id)
    }
}

public final class ToggleSentinel: ToggleSentinelUseCase {
    private let settingsService: any UserSettingsRepositoryProtocol

    public init(userSettingsProtocol: any UserSettingsRepositoryProtocol) {
        settingsService = userSettingsProtocol
    }

    public func execute(for id: String) async throws {
        try await settingsService.toggleSentinel(for: id)
    }
}
