//
// CxpExportViewModel.swift
// Proton Pass - Created on 10/08/2026.
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

import AuthenticationServices
import DIComposition
import Entities
import FactoryKit
import Macro
import Observation
import Stores

@MainActor
@Observable
final class CxpExportViewModel {
    private(set) var verifyingPassword = false
    private(set) var passwordVerified = false
    var passwordVerificationError: (any Error)?

    let vaults: [ShareContent]
    private(set) var selectedShareIds = Set<String>()
    private(set) var exported = false
    var exportErrorMessage: String?

    private let appContentManager = dependency(\ServiceContainer.appContentManager)
    private let cxpExport = dependency(\UseCasesContainer.cxpExport)
    private let window = dependency(\UIComponentsContainer.window)
    private let verifyPassword = dependency(\UseCasesContainer.verifyPassword)

    var selectedCount: Int {
        selectedShareIds.count
    }

    var continueDisabled: Bool {
        selectedShareIds.isEmpty
    }

    init() {
        vaults = (appContentManager.state.loadedContent?.filteredOrderedVaults ?? [])
            .filter { $0.share.vaultContent != nil }
        selectedShareIds = Set(vaults.filter(\.exportable).map(\.share.id))
    }
}

extension CxpExportViewModel {
    func isSelected(_ share: Share) -> Bool {
        selectedShareIds.contains(share.shareId)
    }

    func toggleSelection(_ shareContent: ShareContent) {
        let shareId = shareContent.share.shareId
        if selectedShareIds.contains(shareId) {
            selectedShareIds.remove(shareId)
        } else if shareContent.exportable {
            selectedShareIds.insert(shareId)
        }
    }

    func verify(password: String) {
        Task {
            defer { verifyingPassword = false }
            verifyingPassword = true
            do {
                try await verifyPassword(password)
                passwordVerified = true
            } catch {
                passwordVerificationError = error
            }
        }
    }

    func startExporting() {
        guard #available(iOS 26.0, *) else {
            exported = true
            return
        }

        guard let window else {
            exported = true
            assertionFailure("UIWindow is not injected")
            return
        }

        Task {
            do {
                let shares = vaults.map(\.share).filter { selectedShareIds.contains($0.shareId) }
                try await cxpExport(window: window, shares: shares)
                exported = true
            } catch where error.isCxpExportCancellation {
                exportErrorMessage = #localized("Export cancelled", bundle: .module)
            } catch let error as ASAuthorizationError {
                let message = error.userInfo[NSLocalizedFailureReasonErrorKey] as? String
                exportErrorMessage = message ?? error.localizedDescription
            } catch {
                exportErrorMessage = error.localizedDescription
            }
        }
    }
}

private extension Error {
    /// Cancelled export process surfaces an error from the private
    /// AuthenticationServicesCore framework rather than `ASAuthorizationError.canceled`.
    /// So we have to catch by comparing domain and error code
    var isCxpExportCancellation: Bool {
        let error = self as NSError
        return error.domain == "com.apple.AuthenticationServicesCore.AuthorizationError" && error.code == 2
    }
}

extension ShareContent {
    var exportable: Bool {
        itemCount > 0
    }
}
