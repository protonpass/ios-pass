//
// CxpImportViewModel.swift
// Proton Pass - Created on 02/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

struct CxpImportSummaryRow: Identifiable {
    let title: String
    let total: Int

    var id: String {
        title
    }
}

@MainActor
@Observable
final class CxpImportViewModel {
    let exporterName: String
    let rows: [CxpImportSummaryRow]
    let itemCount: Int
    private(set) var importedCount: Int?
    var importSuccessMessage: String?
    var error: (any Error)?

    private let result: CxpImportResult
    private let importCxpItems = dependency(\UseCasesContainer.importCxpItems)
    private let userManager = dependency(\ServiceContainer.userManager)
    private let logger = dependency(\ToolingContainer.logger)

    var importing: Bool {
        importedCount != nil
    }

    init(result: CxpImportResult) {
        self.result = result
        exporterName = result.exporterName
        let items = result.vaults.flatMap(\.items)
        itemCount = items.count
        rows = Self.summaryRows(for: items)
    }
}

extension CxpImportViewModel {
    func startImporting() {
        Task { [weak self] in
            guard let self else { return }
            defer { importedCount = nil }
            importedCount = 0
            do {
                let userId = try await userManager.getActiveUserId()
                try await importCxpItems(userId: userId, result: result) { [weak self] count in
                    Task { @MainActor [weak self] in
                        guard let self, importing else { return }
                        importedCount = count
                    }
                }
                importSuccessMessage = #localized("%lld items imported", bundle: .module, itemCount)
            } catch {
                self.error = error
                logger.error(error)
            }
        }
    }
}

private extension CxpImportViewModel {
    static func summaryRows(for items: [ItemContentProtobuf]) -> [CxpImportSummaryRow] {
        var logins = 0, totps = 0, notes = 0, passkeys = 0
        var aliases = 0, customs = 0, identities = 0, creditCards = 0
        for item in items {
            totps += item.customFields.count { $0.type == .totp }
            switch item.contentData {
            case let .login(data):
                logins += 1
                passkeys += data.passkeys.count
                if !data.totpUri.isEmpty {
                    totps += 1
                }

            case .note:
                notes += 1

            case .alias:
                aliases += 1

            case .custom, .sshKey, .wifi:
                customs += 1

            case .identity:
                identities += 1

            case .creditCard:
                creditCards += 1
            }
        }

        return [
            .init(title: ItemContentType.login.filterTitle, total: logins),
            .init(title: #localized("TOTP codes", bundle: .module), total: totps),
            .init(title: ItemContentType.note.filterTitle, total: notes),
            .init(title: #localized("Passkeys", bundle: .module), total: passkeys),
            .init(title: ItemContentType.alias.filterTitle, total: aliases),
            .init(title: ItemContentType.custom.filterTitle, total: customs),
            .init(title: ItemContentType.identity.filterTitle, total: identities),
            .init(title: ItemContentType.creditCard.filterTitle, total: creditCards)
        ].filter { $0.total > 0 }
    }
}
