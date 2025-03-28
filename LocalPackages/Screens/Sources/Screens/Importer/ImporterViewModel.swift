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

public protocol ImporterDatasource: Sendable, AnyObject {
    func getUsers() async throws -> [UserUiModel]
    func parseLogins() async throws -> [CsvLogin]
    func proceedImportation(user: UserUiModel?, logins: [CsvLogin]) async throws
}

@MainActor
final class ImporterViewModel: ObservableObject {
    @Published private(set) var logins: [CsvLogin] = []
    @Published private(set) var loading = false
    @Published private var excludedIds: Set<String> = .init()
    @Published private(set) var users: [UserUiModel] = []
    @Published var selectedUser: UserUiModel?
    @Published var importSuccessMessage: String?
    @Published var error: (any Error)?

    private let logger: Logger

    var selectedCount: Int {
        logins.count - excludedIds.count
    }

    weak var datasource: (any ImporterDatasource)?

    init(logManager: any LogManagerProtocol) {
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

    func fetchData() async {
        do {
            defer { loading = false }
            loading = true
            guard let datasource else {
                throw PassError.importer(.missingDatasource)
            }
            users = try await datasource.getUsers()
            selectedUser = users.first
            logins = try await datasource.parseLogins()
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
                guard let datasource else {
                    throw PassError.importer(.missingDatasource)
                }

                guard !logins.isEmpty else {
                    throw PassError.importer(.noLoginsFound)
                }

                let loginsToImport = logins.filter { !excludedIds.contains($0.id) }
                try await datasource.proceedImportation(user: selectedUser,
                                                        logins: loginsToImport)
                importSuccessMessage = #localized("%lld logins imported",
                                                  bundle: .module,
                                                  selectedCount)
            } catch {
                handle(error)
            }
        }
    }

    func handle(_ error: any Error) {
        self.error = error
        logger.error(error)
    }
}
