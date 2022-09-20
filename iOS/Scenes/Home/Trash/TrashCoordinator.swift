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
import ProtonCore_Login
import SwiftUI

final class TrashCoordinator: Coordinator {
    private let symmetricKey: SymmetricKey
    private let shareRepository: ShareRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let trashViewModel: TrashViewModel

    var onRestoredItem: (() -> Void)?

    init(symmetricKey: SymmetricKey,
         shareRepository: ShareRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol) {
        self.symmetricKey = symmetricKey
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.trashViewModel = TrashViewModel(symmetricKey: symmetricKey,
                                             shareRepository: shareRepository,
                                             itemRepository: itemRepository)
        super.init()
        self.start()
    }

    private func start() {
        trashViewModel.delegate = self
        trashViewModel.onToggleSidebar = { [unowned self] in toggleSidebar() }
        trashViewModel.onShowOptions = { [unowned self] item in
            let optionsView = TrashedItemOptionsView(item: item, delegate: self)
            let optionsViewController = UIHostingController(rootView: optionsView)
            if #available(iOS 15.0, *) {
                optionsViewController.sheetPresentationController?.detents = [.medium()]
            }
            presentViewController(optionsViewController)
        }
        trashViewModel.onDeletedItem = { [unowned self] in
            dismissTopMostViewController()
        }
        trashViewModel.onRestoredItem = { [unowned self] in
            dismissTopMostViewController()
            onRestoredItem?()
        }
        start(with: TrashView(viewModel: trashViewModel))
    }

    func refreshTrashedItems() {
        trashViewModel.fetchAllTrashedItems(forceRefresh: false)
    }
}

// MARK: - TrashViewModelDelegate
extension TrashCoordinator: BaseViewModelDelegate {
    func viewModelBeginsLoading() { showLoadingHud() }

    func viewModelStopsLoading() { hideLoadingHud() }

    func viewModelDidFailWithError(_ error: Error) { alertError(error) }
}

// MARK: - TrashedItemOptionsViewDelegate
extension TrashCoordinator: TrashedItemOptionsViewDelegate {
    func trashedItemWantsToBeRestored(_ item: PartialItemContent) {
        trashViewModel.restore(item)
    }

    func trashedItemWantsToShowDetail(_ item: PartialItemContent) {
        print(#function)
    }

    func trashedItemWantsToBeDeletedPermanently(_ item: PartialItemContent) {
        trashViewModel.deletePermanently(item)
    }
}
