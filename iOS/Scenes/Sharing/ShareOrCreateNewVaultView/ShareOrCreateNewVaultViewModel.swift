//
// ShareOrCreateNewVaultViewModel.swift
// Proton Pass - Created on 10/10/2023.
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

import Client
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreUIFoundations

@MainActor
final class ShareOrCreateNewVaultViewModel: ObservableObject {
    @Published private(set) var isFreeUser = true

    let vault: VaultListUiModel
    let itemContent: ItemContent

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private let reachedVaultLimit = resolve(\UseCasesContainer.reachedVaultLimit)
    private let getFeatureFlagStatus = resolve(\SharedUseCasesContainer.getFeatureFlagStatus)
    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)

    var isSecureLinkActive: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passPublicLinkV1)
    }

    var sheetHeight: CGFloat {
        if vault.vault.shared {
            isSecureLinkActive ? 290 : 200
        } else {
            isSecureLinkActive ? 400 : 310
        }
    }

    init(vault: VaultListUiModel, itemContent: ItemContent) {
        self.vault = vault
        self.itemContent = itemContent
        checkIfFreeUser()
    }

    func shareVault() {
        complete(with: .existing(vault.vault))
    }

    func createNewVault() {
        Task { [weak self] in
            guard let self else {
                return
            }
            do {
                if try await reachedVaultLimit() {
                    router.present(for: .upselling(.default))
                } else {
                    complete(with: .new(.defaultNewSharedVault, itemContent))
                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func secureLinkSharing() {
        router.present(for: .createSecureLink(itemContent))
    }

    func manageAccess() {
        router.present(for: .manageShareVault(vault.vault, .topMost))
    }

    private func complete(with vault: SharingVaultData) {
        setShareInviteVault(with: vault)
        router.present(for: .sharingFlow(.topMost))
    }

    func checkIfFreeUser() {
        Task { [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser(userId: nil)
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func upsell(entryPoint: UpsellEntry) {
        router.present(for: .upselling(entryPoint.defaultConfiguration))
    }
}

private extension VaultProtobuf {
    static var defaultNewSharedVault: Self {
        var vault = VaultProtobuf()
        vault.name = #localized("Shared vault")
        vault.display.color = .color3
        vault.display.icon = .icon9
        return vault
    }
}
