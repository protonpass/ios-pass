//
// MainRouter.swift
// Proton Pass - Created on 19/07/2023.
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
@preconcurrency import Combine
import Entities
import ProtonCorePasswordChange
import Screens
import SwiftUI

struct NavigationConfiguration {
    var dismissBeforeShowing = false
    var refresh = false
    var telemetryEvent: TelemetryEventType?

    static var refresh: NavigationConfiguration {
        NavigationConfiguration(refresh: true)
    }

    static func refresh(with event: TelemetryEventType) -> NavigationConfiguration {
        NavigationConfiguration(refresh: true, telemetryEvent: event)
    }

    static var dismissAndRefresh: NavigationConfiguration {
        NavigationConfiguration(dismissBeforeShowing: true, refresh: true)
    }

    static func dismissAndRefresh(with event: TelemetryEventType) -> NavigationConfiguration {
        NavigationConfiguration(dismissBeforeShowing: true, refresh: true, telemetryEvent: event)
    }
}

enum RouterDestination: Hashable, Sendable {
    case urlPage(urlString: String)
    case openSettings
}

enum SheetDismissal {
    case none
    case topMost
    case all
}

extension PasswordChangeModule.PasswordChangeMode: @unchecked Sendable {}

enum SheetDestination: Equatable, Hashable, Sendable {
    case sharingFlow(SheetDismissal)
    case manageShareVault(Vault, SheetDismissal)
    case acceptRejectInvite(UserInvite)
    case vaultCreateEdit(vault: Vault?)
    case upgradeFlow
    case upselling(UpsellingViewConfiguration)
    case logView(module: PassModule)
    case suffixView(SuffixSelection)
    case mailboxView(MailboxSelection, MailboxSection.Mode)
    case autoFillInstructions
    case moveItemsBetweenVaults(MovingContext)
    case fullSync
    case shareVaultFromItemDetail(VaultListUiModel, ItemContent)
    case customizeNewVault(VaultProtobuf, ItemContent)
    case vaultSelection
    case setPINCode
    case search(SearchMode)
    case history(ItemContent)
    case restoreHistory
    case importExport
    case tutorial
    case accountSettings
    case settingsMenu
    case createEditLogin(mode: ItemMode)
    case createItem(item: SymmetricallyEncryptedItem,
                    type: ItemContentType,
                    createPasskeyResponse: CreatePasskeyResponse?)
    case editItem(ItemContent)
    case cloneItem(ItemContent)
    case updateItem(type: ItemContentType, updated: Bool)
    /// automaticDisplay is needed as items details presentation can start from different points and should not
    /// have the same display.
    /// Search and security centre act the same when it comes to display whereas the main list tab has a different
    /// flow.
    case itemDetail(ItemContent, automaticDisplay: Bool = true, showSecurityIssues: Bool = false)
    case editSpotlightSearchableContent
    case editSpotlightSearchableVaults
    case editSpotlightVaults
    case passkeyDetail(Passkey)
    case securityDetail(SecurityWeakness)
    case passwordReusedItemList(ItemContent)
    case changePassword(PasswordChangeModule.PasswordChangeMode)
    case publicLink(ItemContent)
}

enum GenericDestination {
    case presentView(view: any View, dismissible: Bool)
}

// func presentCreateEditLoginView(mode: ItemMode) throws {
//    let viewModel = try CreateEditLoginViewModel(mode: mode,
//                                                 upgradeChecker: upgradeChecker,
//                                                 vaults: vaultsManager.getAllVaults())
//    viewModel.delegate = createEditItemDelegates
//    viewModel.createEditLoginViewModelDelegate = createEditItemDelegates
//    let view = CreateEditLoginView(viewModel: viewModel)
//    present(view, dismissable: false)
//    currentViewModel = viewModel
// }
//
// func presentCreateEditAliasView(mode: ItemMode) throws {
//    let viewModel = try CreateEditAliasViewModel(mode: mode,
//                                                 upgradeChecker: upgradeChecker,
//                                                 vaults: vaultsManager.getAllVaults())
//    viewModel.delegate = createEditItemDelegates
//    let view = CreateEditAliasView(viewModel: viewModel)
//    present(view, dismissable: false)
//    currentViewModel = viewModel
// }
//
// func presentCreateEditCreditCardView(mode: ItemMode) throws {
//    let viewModel = try CreateEditCreditCardViewModel(mode: mode,
//                                                      upgradeChecker: upgradeChecker,
//                                                      vaults: vaultsManager.getAllVaults())
//    viewModel.delegate = createEditItemDelegates
//    let view = CreateEditCreditCardView(viewModel: viewModel)
//    present(view, dismissable: false)
//    currentViewModel = viewModel
// }
//
// func presentCreateEditNoteView(mode: ItemMode) throws {
//    let viewModel = try CreateEditNoteViewModel(mode: mode,
//                                                upgradeChecker: upgradeChecker,
//                                                vaults: vaultsManager.getAllVaults())
//    viewModel.delegate = createEditItemDelegates
//    let view = CreateEditNoteView(viewModel: viewModel)
//    present(view, dismissable: false)
//    currentViewModel = viewModel
// }
//
// func presentCreateEditIdentityView(mode: ItemMode) throws {
////        let viewModel = try CreateEditLoginViewModel(mode: mode,
////                                                     upgradeChecker: upgradeChecker,
////                                                     vaults: vaultsManager.getAllVaults())
//
//    let viewModel = try CreateEditIdentityViewModel(mode: mode,
//                                                    upgradeChecker: upgradeChecker,
//                                                    vaults: vaultsManager.getAllVaults())
////        viewModel.delegate = createEditItemDelegates
////        viewModel.createEditLoginViewModelDelegate = createEditItemDelegates
//    let view = CreateEditIdentityView(viewModel: viewModel)
//    present(view, dismissable: false)
//    currentViewModel = viewModel
// }

// struct Test: Equatable {
//    static func == (lhs: Test, rhs: Test) -> Bool {
//        <#code#>
//    }
//
//    let view: any View
// }

enum UIElementDisplay: Sendable {
    case globalLoading(shouldShow: Bool)
    case displayErrorBanner(any Error)
    case errorMessage(String)
    case successMessage(String? = nil, config: NavigationConfiguration? = nil)
    case infosMessage(String? = nil, config: NavigationConfiguration? = nil)
}

enum AlertDestination: Sendable {
    case bulkPermanentDeleteConfirmation(itemCount: Int)
}

enum ActionDestination: Sendable {
    case copyToClipboard(text: String, message: String)
    case back(isShownAsSheet: Bool)
}

enum DeeplinkDestination: Sendable {
    case totp(String)
    case spotlightItemDetail(ItemContent)
    case error(any Error)
}

final actor MainUIKitSwiftUIRouter: Sendable {
    let newPresentationDestination: PassthroughSubject<RouterDestination, Never> = .init()
    nonisolated let newSheetDestination: PassthroughSubject<SheetDestination, Never> = .init()
    let globalElementDisplay: PassthroughSubject<UIElementDisplay, Never> = .init()
    let alertDestination: PassthroughSubject<AlertDestination, Never> = .init()
    let actionDestination: PassthroughSubject<ActionDestination, Never> = .init()
    let genericDestination: PassthroughSubject<GenericDestination, Never> = .init()

    @MainActor
    private var pendingDeeplinkDestination: DeeplinkDestination?

    @MainActor
    func navigate(to destination: RouterDestination) {
        newPresentationDestination.send(destination)
    }

    @MainActor
    func present(for destination: SheetDestination) {
        newSheetDestination.send(destination)
    }

    @MainActor
    func navigate(to destination: GenericDestination) {
        genericDestination.send(destination)
    }

    @MainActor
    func display(element: UIElementDisplay) {
        globalElementDisplay.send(element)
    }

    @MainActor
    func alert(_ destination: AlertDestination) {
        alertDestination.send(destination)
    }

    @MainActor
    func action(_ destination: ActionDestination) {
        actionDestination.send(destination)
    }

    @MainActor
    func requestDeeplink(_ destination: DeeplinkDestination) {
        pendingDeeplinkDestination = destination
    }

    @MainActor
    func getDeeplink() -> DeeplinkDestination? {
        pendingDeeplinkDestination
    }

    @MainActor
    func resolveDeeplink() {
        pendingDeeplinkDestination = nil
    }
}
