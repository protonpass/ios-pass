//
// TrashCoordinator.swift
// Proton Pass - Created on 07/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Core
import CryptoKit
import MBProgressHUD
import ProtonCore_Login
import SwiftUI
import UIComponents

protocol TrashCoordinatorDelegate: AnyObject {
    func trashCoordinatorDidRestoreItems()
}

final class TrashCoordinator: Coordinator {
    private let symmetricKey: SymmetricKey
    private let shareRepository: ShareRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let aliasRepository: AliasRepositoryProtocol
    private let trashViewModel: TrashViewModel

    weak var trashCoordinatorDelegate: TrashCoordinatorDelegate?
    weak var bannerManager: BannerManager?

    init(symmetricKey: SymmetricKey,
         shareRepository: ShareRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol) {
        self.symmetricKey = symmetricKey
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.aliasRepository = aliasRepository
        self.trashViewModel = TrashViewModel(symmetricKey: symmetricKey,
                                             shareRepository: shareRepository,
                                             itemRepository: itemRepository)
        super.init()
        self.start()
    }

    private func start() {
        trashViewModel.delegate = self
        start(with: TrashView(viewModel: trashViewModel))
    }

    func refreshTrashedItems() {
        trashViewModel.fetchAllTrashedItems(forceRefresh: false)
    }
}

private extension TrashCoordinator {
    func showItemDetailView(_ itemContent: ItemContent) {
        let baseItemDetailViewModel: BaseItemDetailViewModel
        switch itemContent.contentData {
        case .login:
            let viewModel = LogInDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository)
            baseItemDetailViewModel = viewModel
            let logInDetailView = LogInDetailView(viewModel: viewModel)
            pushView(logInDetailView)

        case .note:
            let viewModel = NoteDetailViewModel(itemContent: itemContent,
                                                itemRepository: itemRepository)
            baseItemDetailViewModel = viewModel
            let noteDetailView = NoteDetailView(viewModel: viewModel)
            pushView(noteDetailView)

        case .alias:
            let viewModel = AliasDetailViewModel(itemContent: itemContent,
                                                 itemRepository: itemRepository,
                                                 aliasRepository: aliasRepository)
            baseItemDetailViewModel = viewModel
            let aliasDetailView = AliasDetailView(viewModel: viewModel)
            pushView(aliasDetailView)
        }

        baseItemDetailViewModel.delegate = self
    }
}

// MARK: - MyVaultsCoordinatorDelegate
extension TrashCoordinator: MyVaultsCoordinatorDelegate {
    func myVaultsCoordinatorWantsToRefreshTrash() {
        refreshTrashedItems()
    }
}

// MARK: - TrashViewModelDelegate
extension TrashCoordinator: TrashViewModelDelegate {
    func trashViewModelWantsToToggleSidebar() {
        toggleSidebar()
    }

    func trashViewModelWantsToShowLoadingHud() {
        showLoadingHud()
    }

    func trashViewModelWantsShowItemDetail(_ item: Client.ItemContent) {
        showItemDetailView(item)
    }

    func trashViewModelWantsToHideLoadingHud() {
        hideLoadingHud()
    }

    func trashViewModelDidRestoreItem(_ type: Client.ItemContentType) {
        let message: String
        switch type {
        case .alias: message = "Alias restored"
        case .login: message = "Login restored"
        case .note: message = "Note restored"
        }
        popToRoot()
        bannerManager?.displayBottomInfoMessage(message)
        trashCoordinatorDelegate?.trashCoordinatorDidRestoreItems()
    }

    func trashViewModelDidRestoreAllItems(count: Int) {
        bannerManager?.displayBottomInfoMessage("\(count) item(s) restored")
        trashCoordinatorDelegate?.trashCoordinatorDidRestoreItems()
    }

    func trashViewModelDidDeleteItem(_ type: Client.ItemContentType) {
        let message: String
        switch type {
        case .alias: message = "Alias permanently deleted"
        case .login: message = "Login permanently deleted"
        case .note: message = "Note permanently deleted"
        }
        bannerManager?.displayBottomInfoMessage(message)
    }

    func trashViewModelDidEmptyTrash() {
        bannerManager?.displayBottomInfoMessage("Trash emptied")
    }

    func trashViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}

// MARK: - BaseItemDetailViewModel
extension TrashCoordinator: ItemDetailViewModelDelegate {
    func itemDetailViewModelWantsToEditItem(_ itemContent: Client.ItemContent) {
        print("\(#function) not applicable")
    }

    func itemDetailViewModelWantsToRestore(_ item: ItemListUiModel) {
        trashViewModel.restore(item)
    }

    func itemDetailViewModelWantsToDisplayInformativeMessage(_ message: String) {
        bannerManager?.displayBottomInfoMessage(message)
    }

    func itemDetailViewModelWantsToShowLarge(_ text: String) {
        presentView(LargeView(text: text), dismissible: true)
    }

    func itemDetailViewModelDidFail(_ error: Error) {
        bannerManager?.displayTopErrorMessage(error)
    }
}
