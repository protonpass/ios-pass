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
import Combine
import Entities
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
    case sharingFlow(SheetDismissal)
    case manageShareVault(Vault, SheetDismissal)
    case acceptRejectInvite(UserInvite)
    case vaultCreateEdit(vault: Vault?)
    case upgradeFlow
    case upselling
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
}

enum UIElementDisplay: Sendable {
    case globalLoading(shouldShow: Bool)
    case displayErrorBanner(Error)
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
    case error(Error)
}

@MainActor
final class MainUIKitSwiftUIRouter: Sendable {
    let newPresentationDestination: PassthroughSubject<RouterDestination, Never> = .init()
    let newSheetDestination: PassthroughSubject<SheetDestination, Never> = .init()
    let globalElementDisplay: PassthroughSubject<UIElementDisplay, Never> = .init()
    let alertDestination: PassthroughSubject<AlertDestination, Never> = .init()
    let actionDestination: PassthroughSubject<ActionDestination, Never> = .init()

    private(set) var pendingDeeplinkDestination: DeeplinkDestination?

    func navigate(to destination: RouterDestination) {
        newPresentationDestination.send(destination)
    }

    func present(for destination: SheetDestination) {
        newSheetDestination.send(destination)
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

    func resolveDeeplink() {
        pendingDeeplinkDestination = nil
    }
}

// @available(iOS 16.0, *)
// final class MainNavStackRouter {
//    @Published public var path = NavigationPath()
//    @Published public var presentedSheet: SheetDestination?
//
//    func navigate(to destination: RouterDestination) {
//        path.append(destination)
//    }
//
//    func popToRoot() {
//        path.removeLast(path.count)
//    }
//
//    func back(to numberOfScreen: Int = 1) {
//        path.removeLast(numberOfScreen)
//    }
// }
