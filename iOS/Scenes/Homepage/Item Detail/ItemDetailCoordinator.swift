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
import Entities
import Factory
import SwiftUI
import UIKit

@MainActor
protocol ItemDetailCoordinatorDelegate: AnyObject {
    func itemDetailCoordinatorWantsToPresent(view: any View, asSheet: Bool)
}

@MainActor
final class ItemDetailCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private weak var itemDetailViewModelDelegate: ItemDetailViewModelDelegate?
    private var currentViewModel: BaseItemDetailViewModel?

    weak var delegate: ItemDetailCoordinatorDelegate?

    init(itemDetailViewModelDelegate: ItemDetailViewModelDelegate?) {
        self.itemDetailViewModelDelegate = itemDetailViewModelDelegate
    }

    func showDetail(for itemContent: ItemContent, asSheet: Bool) {
        assert(delegate != nil, "delegate is not set")

        let itemDetailPage: ItemDetailPage = switch itemContent.contentData {
        case .login:
            makeLoginItemDetailPage(from: itemContent, asSheet: asSheet)
        case .note:
            makeNoteDetailPage(from: itemContent, asSheet: asSheet)
        case .alias:
            makeAliasItemDetailPage(from: itemContent, asSheet: asSheet)
        case .creditCard:
            makeCreditCardDetailPage(from: itemContent, asSheet: asSheet)
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

    func makeLoginItemDetailPage(from itemContent: ItemContent, asSheet: Bool) -> ItemDetailPage {
        let viewModel = LogInDetailViewModel(isShownAsSheet: asSheet,
                                             itemContent: itemContent,
                                             upgradeChecker: upgradeChecker)
        viewModel.logInDetailViewModelDelegate = self
        return .init(viewModel: viewModel, view: LogInDetailView(viewModel: viewModel))
    }

    func makeAliasItemDetailPage(from itemContent: ItemContent, asSheet: Bool) -> ItemDetailPage {
        let viewModel = AliasDetailViewModel(isShownAsSheet: asSheet,
                                             itemContent: itemContent,
                                             upgradeChecker: upgradeChecker)
        return .init(viewModel: viewModel, view: AliasDetailView(viewModel: viewModel))
    }

    func makeNoteDetailPage(from itemContent: ItemContent, asSheet: Bool) -> ItemDetailPage {
        let viewModel = NoteDetailViewModel(isShownAsSheet: asSheet,
                                            itemContent: itemContent,
                                            upgradeChecker: upgradeChecker)
        return .init(viewModel: viewModel, view: NoteDetailView(viewModel: viewModel))
    }

    func makeCreditCardDetailPage(from itemContent: ItemContent, asSheet: Bool) -> ItemDetailPage {
        let viewModel = CreditCardDetailViewModel(isShownAsSheet: asSheet,
                                                  itemContent: itemContent,
                                                  upgradeChecker: upgradeChecker)
        return .init(viewModel: viewModel, view: CreditCardDetailView(viewModel: viewModel))
    }
}

// MARK: - LogInDetailViewModelDelegate

extension ItemDetailCoordinator: LogInDetailViewModelDelegate {
    func logInDetailViewModelWantsToShowAliasDetail(_ itemContent: ItemContent) {
        showDetail(for: itemContent, asSheet: true)
    }
}
