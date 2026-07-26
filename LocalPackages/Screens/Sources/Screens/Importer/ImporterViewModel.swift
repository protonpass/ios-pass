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
import DIComposition
import Entities
import FactoryKit
import Foundation
import Macro
import ProtonCoreLogin

@MainActor
@Observable
final class ImporterViewModel {
    private(set) var logins: [CsvLogin] = []
    private(set) var loading = false
    private var excludedIds: Set<String> = .init()
    private(set) var users: [UserUiModel] = []
    var selectedUser: UserUiModel?
    var importSuccessMessage: String?
    var error: (any Error)?

    private let getUsers = dependency(\UseCasesContainer.getUserUiModels)
    private let createVaultAndImportLogins = dependency(\UseCasesContainer.createVaultAndImportLogins)
    private let userManager = dependency(\ServiceContainer.userManager)
    private let logger: Logger

    var selectedCount: Int {
        logins.count - excludedIds.count
    }

    init(logManager: any LogManagerProtocol = ToolingContainer.shared.logManager()) {
        logger = .init(manager: logManager)
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

    func loadData(data: [CsvLogin]) {
        logins = data
    }

    func loadUser() async {
        do {
            users = try await getUsers()
            selectedUser = users.first
        } catch {
            handle(error)
        }
    }

    func startImporting() {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            loading = true
            do {
                guard !logins.isEmpty else {
                    throw PassError.importer(.noLoginsFound)
                }

                let loginsToImport = logins.filter { !excludedIds.contains($0.id) }
                try await proceedImportation(user: selectedUser, logins: loginsToImport)
                importSuccessMessage = #localized("%lld logins imported",
                                                  bundle: .module,
                                                  selectedCount)
            } catch {
                handle(error)
            }
        }
    }

    func handle(_ error: any Error,
                file: String = #file,
                function: String = #function,
                line: UInt = #line,
                column: UInt = #column) {
        self.error = error
        logger.error(error, file: file, function: function, line: line, column: column)
    }
}

private extension ImporterViewModel {
    func proceedImportation(user: UserUiModel?, logins: [CsvLogin]) async throws {
        let userId: String = if let user {
            user.id
        } else {
            try await userManager.getActiveUserId()
        }
        try await createVaultAndImportLogins(userId: userId, logins: logins)
    }
}
