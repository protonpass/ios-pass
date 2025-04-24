//
// CreateEditItemCoordinator.swift
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

import Core
import Entities
import Factory
import ProtonCoreLogin
import SwiftUI
import UIKit

typealias CreateEditItemDelegates =
    CreateEditLoginViewModelDelegate &
    GeneratePasswordCoordinatorDelegate &
    GeneratePasswordViewModelDelegate

@MainActor
final class CreateEditItemCoordinator: DeinitPrintable {
    deinit { print(deinitMessage) }

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private weak var createEditItemDelegates: (any CreateEditItemDelegates)?

    private var currentViewModel: BaseCreateEditItemViewModel?
    private var generatePasswordCoordinator: GeneratePasswordCoordinator?

    init(createEditItemDelegates: (any CreateEditItemDelegates)?) {
        self.createEditItemDelegates = createEditItemDelegates
    }
}

// MARK: - Public APIs

extension CreateEditItemCoordinator {
    /// Refresh currently shown create edit page
    func refresh() {
        currentViewModel?.refresh()
    }

    func presentEditOrCloneItemView(for itemContent: ItemContent, isEdit: Bool) throws {
        let mode = isEdit ? ItemMode.edit(itemContent) : ItemMode.clone(itemContent)
        switch itemContent.contentData.type {
        case .login:
            try presentCreateEditLoginView(mode: mode)
        case .note:
            try presentCreateEditNoteView(mode: mode)
        case .creditCard:
            try presentCreateEditCreditCardView(mode: mode)
        case .alias:
            try presentCreateEditAliasView(mode: mode)
        case .identity:
            try presentCreateEditIdentityView(mode: mode)
        case .sshKey:
            try presentCreateEditSshKeyView(mode: mode)
        case .wifi:
            try presentCreateEditWifiView(mode: mode)
        case .custom:
            try presentCreateEditCustomView(mode: mode)
        }
    }

    @MainActor
    func presentCreateItemView(for itemType: ItemType,
                               onError: @escaping (any Error) -> Void) async throws {
        let shareId = appContentManager.vaultSelection.preciseVault?.shareId
        switch itemType {
        case .login:
            let logInType = ItemCreationType.login(autofill: false)
            try presentCreateEditLoginView(mode: .create(shareId: shareId, type: logInType))
        case .alias:
            try presentCreateEditAliasView(mode: .create(shareId: shareId, type: .alias))
        case .creditCard:
            try presentCreateEditCreditCardView(mode: .create(shareId: shareId, type: .creditCard))
        case .note:
            try presentCreateEditNoteView(mode: .create(shareId: shareId, type: .note(title: "", note: "")))
        case .password:
            presentGeneratePasswordView(mode: .random,
                                        generatePasswordViewModelDelegate: createEditItemDelegates)
        case .identity:
            try presentCreateEditIdentityView(mode: .create(shareId: shareId, type: .identity))
        case .custom:
            try presentCustomItemList(shareId: shareId, onError: onError)
        }
    }

    func presentGeneratePasswordForLoginItem(delegate: any GeneratePasswordViewModelDelegate) {
        presentGeneratePasswordView(mode: .createLogin, generatePasswordViewModelDelegate: delegate)
    }
}

// MARK: - Private APIs

private extension CreateEditItemCoordinator {
    var vaults: [Share] {
        appContentManager.getAllSharesLinkToVault()
    }

    func present(_ view: any View, dismissable: Bool) {
        router.navigate(to: .createEdit(view: view, dismissible: dismissable))
    }

    func presentCreateEditLoginView(mode: ItemMode) throws {
        let viewModel = try CreateEditLoginViewModel(mode: mode,
                                                     upgradeChecker: upgradeChecker,
                                                     vaults: vaults)
        viewModel.delegate = createEditItemDelegates
        let view = CreateEditLoginView(viewModel: viewModel)
        present(view, dismissable: false)
        currentViewModel = viewModel
    }

    func presentCreateEditAliasView(mode: ItemMode) throws {
        let viewModel = try CreateEditAliasViewModel(mode: mode,
                                                     upgradeChecker: upgradeChecker,
                                                     vaults: appContentManager.getAllShares())
        let view = CreateEditAliasView(viewModel: viewModel)
        present(view, dismissable: false)
        currentViewModel = viewModel
    }

    func presentCreateEditCreditCardView(mode: ItemMode) throws {
        let viewModel = try CreateEditCreditCardViewModel(mode: mode,
                                                          upgradeChecker: upgradeChecker,
                                                          vaults: appContentManager.getAllShares())
        let view = CreateEditCreditCardView(viewModel: viewModel)
        present(view, dismissable: false)
        currentViewModel = viewModel
    }

    func presentCreateEditNoteView(mode: ItemMode) throws {
        let viewModel = try CreateEditNoteViewModel(mode: mode,
                                                    upgradeChecker: upgradeChecker,
                                                    vaults: appContentManager.getAllShares())
        let view = CreateEditNoteView(viewModel: viewModel)
        present(view, dismissable: false)
        currentViewModel = viewModel
    }

    func presentCreateEditIdentityView(mode: ItemMode) throws {
        let viewModel = try CreateEditIdentityViewModel(mode: mode,
                                                        upgradeChecker: upgradeChecker,
                                                        vaults: appContentManager.getAllShares())
        let view = CreateEditIdentityView(viewModel: viewModel)
        present(view, dismissable: false)
        currentViewModel = viewModel
    }

    func presentCreateEditSshKeyView(mode: ItemMode) throws {
        let viewModel = try CreateEditSshKeyViewModel(mode: mode,
                                                      upgradeChecker: upgradeChecker,
                                                      vaults: appContentManager.getAllShares())
        let view = CreateEditSshKeyView(viewModel: viewModel)
        present(view, dismissable: false)
        currentViewModel = viewModel
    }

    func presentCreateEditWifiView(mode: ItemMode) throws {
        let viewModel = try CreateEditWifiViewModel(mode: mode,
                                                    upgradeChecker: upgradeChecker,
                                                    vaults: appContentManager.getAllShares())
        let view = CreateEditWifiView(viewModel: viewModel)
        present(view, dismissable: false)
        currentViewModel = viewModel
    }

    func presentCreateEditCustomView(mode: ItemMode) throws {
        let viewModel = try CreateEditCustomItemViewModel(mode: mode,
                                                          upgradeChecker: upgradeChecker,
                                                          vaults: appContentManager.getAllShares())
        let view = CreateEditCustomItemView(viewModel: viewModel)
        present(view, dismissable: false)
        currentViewModel = viewModel
    }

    func presentGeneratePasswordView(mode: GeneratePasswordViewMode,
                                     generatePasswordViewModelDelegate: (any GeneratePasswordViewModelDelegate)?) {
        Task { [weak self] in
            guard let self else { return }
            let coordinator =
                GeneratePasswordCoordinator(generatePasswordViewModelDelegate: generatePasswordViewModelDelegate,
                                            mode: mode)
            coordinator.delegate = createEditItemDelegates
            coordinator.start()
            generatePasswordCoordinator = coordinator
        }
    }
}

// MARK: - Custom item

private extension CreateEditItemCoordinator {
    func presentCustomItemList(shareId: String?, onError: @escaping (any Error) -> Void) throws {
        let view = CustomItemTemplatesList { [weak self] template in
            guard let self else { return }
            do {
                try handle(template: template, shareId: shareId)
            } catch {
                onError(error)
            }
        }

        present(view, dismissable: true)
    }

    func handle(template: CustomItemTemplate, shareId: String?) throws {
        switch template {
        case .sshKey:
            try presentCreateEditSshKeyView(mode: .create(shareId: shareId, type: .sshKey))
        case .wifi:
            try presentCreateEditWifiView(mode: .create(shareId: shareId, type: .wifi))
        default:
            try presentCreateEditCustomView(mode: .create(shareId: shareId, type: .custom(template)))
        }
    }
}
