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

@MainActor
@Observable
final class CxpImportViewModel {
    let exporterName: String
    let rows: [CxpImportSummaryUiModel]
    let itemCount: Int
    private(set) var importedCount: Int?
    var importSuccessMessage: String?
    var errorMessage: String?

    private let result: CxpImportResult
    private let getCxpImportSummary = dependency(\UseCasesContainer.getCxpImportSummary)
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
        rows = getCxpImportSummary(items: items)
    }
}

extension CxpImportViewModel {
    /// One-shot: a failure can leave some vaults imported, so retrying would duplicate them
    func startImporting() {
        guard importedCount == nil else { return }
        importedCount = 0
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                try await importCxpItems(userId: userId,
                                         result: result,
                                         defaultVaultContent: .importedVault()) { @MainActor [weak self] count in
                    guard let self else { return }
                    importedCount = count
                }
                importSuccessMessage = #localized("%lld items imported", bundle: .module, itemCount)
            } catch PassError.importer(.vaultLimitReached) {
                errorMessage = #localized("Upgrade your plan to get enough vaults for this import.",
                                          bundle: .module)
            } catch PassError.importer(.vaultCreationNotAllowed) {
                errorMessage = #localized("Your organization doesn't allow creating the vaults this import needs.",
                                          bundle: .module)
            } catch {
                errorMessage = error.localizedDebugDescription
                logger.error(error)
            }
        }
    }
}
