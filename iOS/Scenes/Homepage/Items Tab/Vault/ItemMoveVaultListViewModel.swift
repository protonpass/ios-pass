//
// ItemMoveVaultListViewModel.swift
// Proton Pass - Created on 29/03/2023.
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
import Combine
import Core
import Entities
import FactoryKit
import Macro

@MainActor
final class ItemMoveVaultListViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let moveItemsBetweenContainers = resolve(\UseCasesContainer.moveItemsBetweenContainers)
    private let currentSelectedItems = resolve(\DataStreamContainer.currentSelectedItems)
    @LazyInjected(\SharedServiceContainer.appContentManager) private var appContentManager
    @LazyInjected(\SharedRepositoryContainer.itemRepository) private var itemRepository
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus

    @Published private(set) var isFreeUser = false
    @Published private(set) var showWarning = false
    @Published var selectedContainer: ShareSelectionPayload?
    @Published var expandedContainerIds = Set<String>()

    let allSharesContent: [ShareContent]
    private let context: MovingContext

    var folderSupported: Bool {
        getFeatureFlagStatus(for: FeatureFlagType.passFolder)
    }

    init(allVaults: [ShareContent], context: MovingContext) {
        allSharesContent = allVaults.sortedByHidden()
        self.context = context
        let fromShareId: String? = switch context {
        case let .singleItem(item):
            item.shareId
        case let .allItems(vault):
            vault.shareId
        case let .allItemsInFolder(folder):
            folder.shareId
        case .selectedItems:
            nil
        }

        if let fromShareId,
           let shareContent = appContentManager
           .getShareContent(for: fromShareId) {
            selectedContainer = ShareSelectionPayload(share: shareContent.share, folder: nil)
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()

                if case let .singleItem(item) = context {
                    if let item = try await itemRepository.getItem(shareId: item.shareId,
                                                                   itemId: item.itemId) {
                        showWarning = item.item.revision > 50
                    }
                }
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func doMove() {
        guard let selectedContainer,
              selectedContainer.share.isVaultRepresentation else {
            assertionFailure("Should have a selected container")
            return
        }
        Task { [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                try await moveItemsBetweenContainers(context: context,
                                                     to: selectedContainer.share.shareId,
                                                     destinationFolderId: selectedContainer.folder?.folderId)
                router.display(element: successMessage(toVaultName: selectedContainer.title))
                currentSelectedItems.send([])
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func toggleDisplayContainerContent(containerId: String) {
        if expandedContainerIds.remove(containerId) == nil {
            expandedContainerIds.insert(containerId)
        }
    }
}

private extension ItemMoveVaultListViewModel {
    func successMessage(toVaultName: String) -> UIElementDisplay {
        switch context {
        case let .singleItem(item):
            let message = #localized("Item moved to vault « %@ »", toVaultName)
            return .successMessage(message, config: .dismissAndRefresh(with: .update(item.type)))
        case let .allItems(fromVault):
            let message = #localized("Items from « %@ » moved to vault « %@ »", fromVault.vaultName ?? "",
                                     toVaultName)
            return .successMessage(message, config: .dismissAndRefresh)
        case let .allItemsInFolder(folder):
            let message = #localized("Items from folder « %@ » moved to vault « %@ »",
                                     folder.content.name, toVaultName)
            return .successMessage(message, config: .dismissAndRefresh)
        case let .selectedItems(items):
            let message = #localized("%lld items moved to vault « %@ »", items.count, toVaultName)
            return .successMessage(message, config: .dismissAndRefresh)
        }
    }
}
