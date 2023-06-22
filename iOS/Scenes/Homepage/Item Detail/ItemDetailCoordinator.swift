//
// ItemDetailCoordinator.swift
// Proton Pass - Created on 10/05/2023.
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
import Core
import SwiftUI
import UIKit

protocol ItemDetailCoordinatorDelegate: AnyObject {
    func itemDetailCoordinatorWantsToPresent(view: any View, asSheet: Bool)
}

final class ItemDetailCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    private let aliasRepository: AliasRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let favIconRepository: FavIconRepositoryProtocol
    private let upgradeChecker: UpgradeCheckerProtocol
    private let logManager: LogManager
    private let preferences: Preferences
    private let vaultsManager: VaultsManager
    private weak var itemDetailViewModelDelegate: ItemDetailViewModelDelegate?
    private var currentViewModel: BaseItemDetailViewModel?

    weak var delegate: ItemDetailCoordinatorDelegate?

    init(aliasRepository: AliasRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         favIconRepository: FavIconRepositoryProtocol,
         upgradeChecker: UpgradeCheckerProtocol,
         logManager: LogManager,
         preferences: Preferences,
         vaultsManager: VaultsManager,
         itemDetailViewModelDelegate: ItemDetailViewModelDelegate?) {
        self.aliasRepository = aliasRepository
        self.itemRepository = itemRepository
        self.favIconRepository = favIconRepository
        self.upgradeChecker = upgradeChecker
        self.logManager = logManager
        self.preferences = preferences
        self.vaultsManager = vaultsManager
        self.itemDetailViewModelDelegate = itemDetailViewModelDelegate
    }

    func showDetail(for itemContent: ItemContent, asSheet: Bool) {
        assert(delegate != nil, "delegate is not set")

        // Only show vault when there're more than 1 vault
        var vault: Vault?
        let allVaults = vaultsManager.getAllVaults()
        if allVaults.count > 1 {
            vault = allVaults.first(where: { $0.shareId == itemContent.shareId })
        }

        let itemDetailPage: ItemDetailPage
        switch itemContent.contentData {
        case .login:
            itemDetailPage = makeLoginItemDetailPage(from: itemContent, asSheet: asSheet, vault: vault)
        case .note:
            itemDetailPage = makeNoteDetailPage(from: itemContent, asSheet: asSheet, vault: vault)
        case .alias:
            itemDetailPage = makeAliasItemDetailPage(from: itemContent, asSheet: asSheet, vault: vault)
        case .creditCard:
            itemDetailPage = makeCreditCardDetailPage(from: itemContent, asSheet: asSheet, vault: vault)
        }

        itemDetailPage.viewModel.delegate = itemDetailViewModelDelegate
        currentViewModel = itemDetailPage.viewModel

        delegate?.itemDetailCoordinatorWantsToPresent(view: itemDetailPage.view, asSheet: asSheet)
    }

    /// Refresh the currently presented item detail page
    func refresh() {
        currentViewModel?.refresh()
    }
}

private extension ItemDetailCoordinator {
    struct ItemDetailPage {
        let viewModel: BaseItemDetailViewModel
        let view: any View
    }

    func makeLoginItemDetailPage(from itemContent: ItemContent,
                                 asSheet: Bool,
                                 vault: Vault?) -> ItemDetailPage {
        let viewModel = LogInDetailViewModel(isShownAsSheet: asSheet,
                                             itemContent: itemContent,
                                             favIconRepository: favIconRepository,
                                             itemRepository: itemRepository,
                                             upgradeChecker: upgradeChecker,
                                             vault: vault,
                                             logManager: logManager,
                                             theme: preferences.theme)
        viewModel.logInDetailViewModelDelegate = self
        return .init(viewModel: viewModel, view: LogInDetailView(viewModel: viewModel))
    }

    func makeAliasItemDetailPage(from itemContent: ItemContent,
                                 asSheet: Bool,
                                 vault: Vault?) -> ItemDetailPage {
        let viewModel = AliasDetailViewModel(isShownAsSheet: asSheet,
                                             itemContent: itemContent,
                                             favIconRepository: favIconRepository,
                                             itemRepository: itemRepository,
                                             aliasRepository: aliasRepository,
                                             upgradeChecker: upgradeChecker,
                                             vault: vault,
                                             logManager: logManager,
                                             theme: preferences.theme)
        return .init(viewModel: viewModel, view: AliasDetailView(viewModel: viewModel))
    }

    func makeNoteDetailPage(from itemContent: ItemContent,
                            asSheet: Bool,
                            vault: Vault?) -> ItemDetailPage {
        let viewModel = NoteDetailViewModel(isShownAsSheet: asSheet,
                                            itemContent: itemContent,
                                            favIconRepository: favIconRepository,
                                            itemRepository: itemRepository,
                                            upgradeChecker: upgradeChecker,
                                            vault: vault,
                                            logManager: logManager,
                                            theme: preferences.theme)
        return .init(viewModel: viewModel, view: NoteDetailView(viewModel: viewModel))
    }

    func makeCreditCardDetailPage(from itemContent: ItemContent,
                                  asSheet: Bool,
                                  vault: Vault?) -> ItemDetailPage {
        let viewModel = CreditCardDetailViewModel(isShownAsSheet: asSheet,
                                                  itemContent: itemContent,
                                                  favIconRepository: favIconRepository,
                                                  itemRepository: itemRepository,
                                                  upgradeChecker: upgradeChecker,
                                                  vault: vault,
                                                  logManager: logManager,
                                                  theme: preferences.theme)
        return .init(viewModel: viewModel, view: CreditCardDetailView(viewModel: viewModel))
    }
}

// MARK: - LogInDetailViewModelDelegate

extension ItemDetailCoordinator: LogInDetailViewModelDelegate {
    func logInDetailViewModelWantsToShowAliasDetail(_ itemContent: ItemContent) {
        showDetail(for: itemContent, asSheet: true)
    }
}
