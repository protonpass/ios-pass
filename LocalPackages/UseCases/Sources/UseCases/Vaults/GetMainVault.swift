//
//
// GetMainVault.swift
// Proton Pass - Created on 03/10/2023.
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
//

import Client
import Entities

public protocol GetMainVaultUseCase: Sendable {
    func execute() async -> Share?
}

public extension GetMainVaultUseCase {
    func callAsFunction() async -> Share? {
        await execute()
    }
}

public final class GetMainVault: GetMainVaultUseCase {
    private let appContentManager: any AppContentManagerProtocol

    public init(appContentManager: any AppContentManagerProtocol) {
        self.appContentManager = appContentManager
    }

    public func execute() async -> Share? {
        appContentManager.getOldestOwnedVault()
    }
}
