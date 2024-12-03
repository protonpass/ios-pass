//
// ShareElementViewModel.swift
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
final class ShareElementViewModel: ObservableObject {
    @Published private(set) var isFreeUser = true

    let share: Share
    let itemContent: ItemContent
    let itemCount: Int?

    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus
    @LazyInjected(\SharedRepositoryContainer.shareRepository) private var shareRepository

    var sheetHeight: CGFloat {
        350
    }

    var itemSharingEnabled: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passItemSharingV1)
    }

    init(share: Share, itemContent: ItemContent, itemCount: Int?) {
        self.share = share
        self.itemContent = itemContent
        self.itemCount = itemCount
        checkIfFreeUser()
    }

    func shareVault() {
        complete(with: .vault(share))
    }

    func secureLinkSharing() {
        router.present(for: .createSecureLink(itemContent))
    }

    func manageAccess() {
        router.present(for: .manageSharedShare(share, .topMost))
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
                guard let share = try await shareRepository.getShare(shareId: itemContent.shareId) else {
                    throw PassError.sharing(.failedToInvite)
                }

                setShareInviteVault(with: .item(item: itemContent, share: share))
                router.present(for: .sharingFlow(.topMost))
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
