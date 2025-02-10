//
// ActionViewModel.swift
// Proton Pass - Created on 10/02/2025.
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

import Entities
import Factory
@preconcurrency import Foundation
import UniformTypeIdentifiers

@MainActor
final class ActionViewModel: ObservableObject {
    @Published private(set) var users: [UserUiModel] = []
    @Published private(set) var logins: FetchableObject<[CsvLogin]> = .fetching

    @LazyInjected(\SharedToolingContainer.logger) private var logger
    @LazyInjected(\SharedToolingContainer.logManager) var logManager
    @LazyInjected(\SharedServiceContainer.userManager) var userManager
    @LazyInjected(\SharedUseCasesContainer.getUserUiModels) var getUserUiModels
    @LazyInjected(\SharedUseCasesContainer.parseCsvLogins) private var parseCsvLogins
    @LazyInjected(\SharedUseCasesContainer.createVaultAndImportLogins)
    private var createVaultAndImportLogins

    private weak var context: NSExtensionContext?

    init(context: NSExtensionContext?) {
        self.context = context
    }
}

extension ActionViewModel {
    func getUsersAndParseCsv() async {
        do {
            logins = .fetching
            users = try await getUserUiModels()

            guard let items = context?.inputItems as? [NSExtensionItem] else {
                throw PassError.extension(.noInputItems)
            }

            var csvString: String?
            for item in items {
                guard let attachments = item.attachments else {
                    throw PassError.extension(.noAttachments)
                }

                let id = UTType.commaSeparatedText.identifier

                for provider in attachments {
                    if provider.hasItemConformingToTypeIdentifier(id),
                       let url = try await provider.loadItem(forTypeIdentifier: id) as? URL {
                        let data = try Data(contentsOf: url)
                        csvString = String(data: data, encoding: .utf8)
                    }
                }
            }

            guard let csvString else {
                throw PassError.extension(.noCsvContent)
            }

            let logins = try await parseCsvLogins(csvString)
            self.logins = .fetched(logins)
        } catch {
            logger.error(error)
            logins = .error(error)
        }
    }

    func proceedImportation(user: UserUiModel?, logins: [CsvLogin]) async throws {
        let userId: String = if let user {
            user.id
        } else {
            try await userManager.getActiveUserId()
        }
        try await createVaultAndImportLogins(userId: userId, logins: logins)
    }

    func dismiss() {
        context?.completeRequest(returningItems: nil)
    }
}
