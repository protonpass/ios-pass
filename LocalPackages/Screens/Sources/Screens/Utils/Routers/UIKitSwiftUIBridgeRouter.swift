//
// UIKitSwiftUIBridgeRouter.swift
// Proton Pass - Created on 16/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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
@preconcurrency import SwiftUI

public struct NavigationConfiguration {
    public var dismissBeforeShowing = false
    public var refresh = false
    public var telemetryEvent: TelemetryEventType?

    public init(dismissBeforeShowing: Bool = false,
                refresh: Bool = false,
                telemetryEvent: TelemetryEventType? = nil) {
        self.dismissBeforeShowing = dismissBeforeShowing
        self.refresh = refresh
        self.telemetryEvent = telemetryEvent
    }

    public static var refresh: NavigationConfiguration {
        NavigationConfiguration(refresh: true)
    }

    public static func refresh(with event: TelemetryEventType) -> NavigationConfiguration {
        NavigationConfiguration(refresh: true, telemetryEvent: event)
    }

    public static var dismissAndRefresh: NavigationConfiguration {
        NavigationConfiguration(dismissBeforeShowing: true, refresh: true)
    }

    public static func dismissAndRefresh(with event: TelemetryEventType) -> NavigationConfiguration {
        NavigationConfiguration(dismissBeforeShowing: true, refresh: true, telemetryEvent: event)
    }
}

public enum RouterDestination: Hashable {
    case urlPage(urlString: String)
    case openSettings
}

public enum SheetDismissal {
    case none
    case topMost
    case all
}

public enum SheetDestination: Equatable, Hashable {
    case alert(UIAlertController)
    case sharingFlow(SheetDismissal)
    case manageSharedShare(ManageSharedDisplay, SheetDismissal)
    case acceptRejectInvite(Invite)
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
    /// iOS 26+ only
    case createNewItem
    case createEditLogin(mode: Entities.ItemMode, dismissAllSheets: Bool)
    case createItem(item: SymmetricallyEncryptedItem,
                    type: ItemContentType,
                    aliasToCopy: String?,
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
    case undecryptableSharesBanner(dismissTopSheetBeforeShowing: Bool)
    case shareLogs(URL)
    case moveFolder(FolderToMove)
    /// iOS 26+ only
    case searchPinnedItems
}

public enum ItemDestination {
    case createEdit(view: any View, dismissible: Bool)
    case detail(view: any View, asSheet: Bool)
}

public enum UIElementDisplay {
    case globalLoading(shouldShow: Bool)
    case displayErrorBanner(any Error)
    case errorMessage(String)
    case successMessage(String? = nil, config: NavigationConfiguration? = nil)
    case infosMessage(String? = nil,
                      // Sometimes we don't want to show a toast message over a presented sheet
                      // (e.g. we don't want to display  "The app is ready to use" toast while onboarding the
                      // user)
                      showWhenNoSheets: Bool = false,
                      config: NavigationConfiguration? = nil)
}

public enum AlertDestination {
    case bulkPermanentDeleteConfirmation(itemCount: Int, aliasCount: Int)
}

public enum ActionDestination {
    case copyToClipboard(text: String, message: String? = nil)
    case back(isShownAsSheet: Bool)
    case manage(userId: String)
    case signOut(userId: String)
    case deleteAccount(userId: String)
    case screenDismissal(SheetDismissal)
}

public enum DeeplinkDestination {
    case totp(String)
    case spotlightItemDetail(ItemContent)
    case error(any Error)
}

public enum GenericDestination {
    case sheet(any View)
    case fullScreen(any View)
}

@MainActor
public protocol UIKitSwiftUIBridgeRouterProtocol: Sendable {
    nonisolated var newPresentationDestination: PassthroughSubject<RouterDestination, Never> { get }
    nonisolated var newSheetDestination: PassthroughSubject<SheetDestination, Never> { get }
    nonisolated var globalElementDisplay: PassthroughSubject<UIElementDisplay, Never> { get }
    nonisolated var alertDestination: PassthroughSubject<AlertDestination, Never> { get }
    nonisolated var actionDestination: PassthroughSubject<ActionDestination, Never> { get }
    nonisolated var itemDestination: PassthroughSubject<ItemDestination, Never> { get }
    nonisolated var genericDestination: PassthroughSubject<GenericDestination, Never> { get }

    func navigate(to destination: RouterDestination)
    func present(for destination: SheetDestination)
    func navigate(to destination: ItemDestination)
    func navigate(to destination: GenericDestination)
    func display(element: UIElementDisplay)
    func alert(_ destination: AlertDestination)
    func action(_ destination: ActionDestination)
    func requestDeeplink(_ destination: DeeplinkDestination)
    func getDeeplink() -> DeeplinkDestination?
    func resolveDeeplink()
}

@MainActor
final class UIKitSwiftUIBridgeRouter: UIKitSwiftUIBridgeRouterProtocol {
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
