//
// CreateVaultAndImportLogins.swift
// Proton Pass - Created on 06/02/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Foundation

public protocol CreateVaultAndImportLoginsUseCase: Sendable {
    func execute(userId: String, logins: [CsvLogin], vaultName: String?) async throws
}

public extension CreateVaultAndImportLoginsUseCase {
    func callAsFunction(userId: String,
                        logins: [CsvLogin],
                        vaultName: String? = nil) async throws {
        try await execute(userId: userId, logins: logins, vaultName: vaultName)
    }
}

public final class CreateVaultAndImportLogins: CreateVaultAndImportLoginsUseCase {
    private let shareRepository: any ShareRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol

    public init(shareRepository: any ShareRepositoryProtocol,
                itemRepository: any ItemRepositoryProtocol) {
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
    }

    public func execute(userId: String, logins: [CsvLogin], vaultName: String?) async throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let vaultName = vaultName ?? "Imported on \(formatter.string(from: .now))"
        let share = try await shareRepository.createVault(userId: userId,
                                                          vault: .init(name: vaultName,
                                                                       description: "",
                                                                       color: .color1,
                                                                       icon: .icon1))
        try await itemRepository.importLogins(userId: userId,
                                              shareId: share.shareId,
                                              logins: logins)
    }
}
