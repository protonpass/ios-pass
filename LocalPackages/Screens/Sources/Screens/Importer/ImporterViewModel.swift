//
// ImporterViewModel.swift
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

import Core
import Entities
import Foundation
import Macro
import ProtonCoreLogin

@MainActor
final class ImporterViewModel: ObservableObject {
    @Published private(set) var importing = false
    @Published private var excludedIds: Set<String> = .init()
    @Published var selectedUser: UserUiModel?
    @Published var importSuccessMessage: String?
    @Published var error: (any Error)?

    private let proceedImportation: (UserUiModel?, [CsvLogin]) async throws -> Void
    private let logger: Logger
    let users: [UserUiModel]
    let logins: [CsvLogin]

    var selectedCount: Int {
        logins.count - excludedIds.count
    }

    init(logManager: any LogManagerProtocol,
         users: [UserUiModel],
         logins: [CsvLogin],
         proceedImportation: @escaping (UserUiModel?, [CsvLogin]) async throws -> Void) {
        logger = .init(manager: logManager)
        self.users = users
        selectedUser = users.first
        self.logins = logins
        self.proceedImportation = proceedImportation
    }
}

extension ImporterViewModel {
    func isSelected(_ login: CsvLogin) -> Bool {
        !excludedIds.contains { $0 == login.id }
    }

    func toggleSelection(_ login: CsvLogin) {
        if excludedIds.contains(where: { $0 == login.id }) {
            excludedIds.remove(login.id)
        } else {
            excludedIds.insert(login.id)
        }
    }

    func startImporting() {
        Task { [weak self] in
            guard let self else { return }
            defer { importing = false }
            importing = true
            do {
                let loginsToImport = logins.filter { !excludedIds.contains($0.id) }
                try await proceedImportation(selectedUser, loginsToImport)
                importSuccessMessage = #localized("%lld logins imported", selectedCount)
            } catch {
                self.error = error
                logger.error(error)
            }
        }
    }
}
