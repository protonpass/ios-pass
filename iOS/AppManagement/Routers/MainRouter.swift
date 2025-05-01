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
@preconcurrency import ProtonCorePasswordChange
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

enum SheetDestination: Equatable, Hashable, Sendable {
    case alert(UIAlertController)
    case sharingFlow(SheetDismissal)
    case manageSharedShare(ManageSharedDisplay, SheetDismissal)
    case acceptRejectInvite(UserInvite)
    case vaultCreateEdit(vault: Share?)
    case upgradeFlow
    case upselling(UpsellingViewConfiguration, SheetDismissal = .all)
    case logView(module: PassModule)
    case autoFillInstructions
    case moveItemsBetweenVaults(MovingContext)
    case fullSync
    case shareVaultFromItemDetail(VaultListUiModel, ItemContent)
    case customizeNewVault(VaultContent, ItemContent)
    case setPINCode
    case history(ItemContent)
    case restoreHistory
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
    case securityKeys
    case passwordReusedItemList(ItemContent)
    case changePassword(PasswordChangeModule.PasswordChangeMode)
    case createSecureLink(ItemContent, Share)
    case enableExtraPassword
    case secureLinks
    case secureLinkDetail(SecureLinkListUIModel)
    case addAccount
    case simpleLoginSyncActivation(dismissAllSheets: Bool)
    case aliasesSyncConfiguration
    case loginsWith2fa
    case breachDetail(Breach)
    case breach(BreachDetailsInfo)
    case addMailbox
    case passwordHistory
    case signInToAnotherDevice
}

enum ItemDestination {
    case createEdit(view: any View, dismissible: Bool)
    case detail(view: any View, asSheet: Bool)
}

enum UIElementDisplay: Sendable {
    case globalLoading(shouldShow: Bool)
    case displayErrorBanner(any Error)
    case errorMessage(String)
    case successMessage(String? = nil, config: NavigationConfiguration? = nil)
    case infosMessage(String? = nil,
                      /// Sometimes we don't want to show a toast message over a presented sheet
                      /// (e.g. we don't want to display  "The app is ready to use" toast while onboarding the
                      /// user)
                      showWhenNoSheets: Bool = false,
                      config: NavigationConfiguration? = nil)
}

enum AlertDestination: Sendable {
    case bulkPermanentDeleteConfirmation(itemCount: Int, aliasCount: Int)
}

enum ActionDestination: Sendable {
    case copyToClipboard(text: String, message: String)
    case back(isShownAsSheet: Bool)
    case manage(userId: String)
    case signOut(userId: String)
    case deleteAccount(userId: String)
    case screenDismissal(SheetDismissal)
}

enum DeeplinkDestination: Sendable {
    case totp(String)
    case spotlightItemDetail(ItemContent)
    case error(any Error)
}

enum GenericDestination: Sendable {
    case sheet(any View)
    case fullScreen(any View)
}

@MainActor
final class MainUIKitSwiftUIRouter {
    nonisolated let newPresentationDestination: PassthroughSubject<RouterDestination, Never> = .init()
    nonisolated let newSheetDestination: PassthroughSubject<SheetDestination, Never> = .init()
    nonisolated let globalElementDisplay: PassthroughSubject<UIElementDisplay, Never> = .init()
    nonisolated let alertDestination: PassthroughSubject<AlertDestination, Never> = .init()
    nonisolated let actionDestination: PassthroughSubject<ActionDestination, Never> = .init()
    nonisolated let itemDestination: PassthroughSubject<ItemDestination, Never> = .init()
    nonisolated let genericDestination: PassthroughSubject<GenericDestination, Never> = .init()

    private var pendingDeeplinkDestination: DeeplinkDestination?

    func navigate(to destination: RouterDestination) {
        newPresentationDestination.send(destination)
    }

    func present(for destination: SheetDestination) {
        newSheetDestination.send(destination)
    }

    func navigate(to destination: ItemDestination) {
        itemDestination.send(destination)
    }

    func navigate(to destination: GenericDestination) {
        genericDestination.send(destination)
    }

    func display(element: UIElementDisplay) {
        globalElementDisplay.send(element)
    }

    func alert(_ destination: AlertDestination) {
        alertDestination.send(destination)
    }

    func action(_ destination: ActionDestination) {
        actionDestination.send(destination)
    }

    func requestDeeplink(_ destination: DeeplinkDestination) {
        pendingDeeplinkDestination = destination
    }

    func getDeeplink() -> DeeplinkDestination? {
        pendingDeeplinkDestination
    }

    func resolveDeeplink() {
        pendingDeeplinkDestination = nil
    }
}
