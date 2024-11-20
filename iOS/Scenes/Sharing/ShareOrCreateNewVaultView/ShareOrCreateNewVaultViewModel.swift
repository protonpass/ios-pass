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
    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus
    @LazyInjected(\SharedRepositoryContainer.shareRepository) private var shareRepository

    var sheetHeight: CGFloat {
        vault.vault.shared ? 400 : canShareItem ? 550 : 450
    }

    var itemSharingEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passItemSharingV1)
    }

    //TODO: this will have to be not dependent on vault but shares
    var canShareItem: Bool {
        vault.vault.isOwner && vault.vault.isAdmin
    }

    init(vault: VaultListUiModel, itemContent: ItemContent) {
        self.vault = vault
        self.itemContent = itemContent
        checkIfFreeUser()
    }

    func shareVault() {
        complete(with: .vault(vault.vault))
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

    private func complete(with element: SharingElementData) {
        setShareInviteVault(with: element)
        router.present(for: .sharingFlow(.topMost))
    }

    func checkIfFreeUser() {
        Task { [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func upsell(entryPoint: UpsellEntry) {
        router.present(for: .upselling(entryPoint.defaultConfiguration))
    }

    func shareItem() {
        Task {
            do {
                guard let share = try await shareRepository.getShareItem(shareId: itemContent.shareId) else {
                    router.display(element: .errorMessage("Could not find a share linked to this item"))
                    return
                }

                let sharedItem = ShareItem(itemUuid: itemContent.itemUuid,
                                           vaultID: share.vaultID,
                                           shareId: share.shareID,
                                           addressId: share.addressID,
                                           name: itemContent.name,
                                           isOwner: share.owner,
                                           shareRole: ShareRole(rawValue: share.shareRoleID) ?? .read,
                                           members: Int(share.targetMembers),
                                           maxMembers: Int(share.targetMaxMembers),
                                           pendingInvites: Int(share.pendingInvites),
                                           newUserInvitesReady: Int(share.newUserInvitesReady),
                                           shared: share.shared,
                                           createTime: share.createTime,
                                           canAutoFill: share.canAutoFill,
                                           note: itemContent.note,
                                           contentData: itemContent.contentData)
                setShareInviteVault(with: .item(itemId: itemContent.itemId, sharedItem: sharedItem))
                router.present(for: .sharingFlow(.topMost))
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
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
