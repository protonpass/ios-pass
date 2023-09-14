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
import SwiftUI

struct NavigationConfiguration {
    var dismissBeforeShowing = false
    var refresh = false
    var telemetryEvent: TelemetryEventType?

    static var refresh: NavigationConfiguration {
        NavigationConfiguration(refresh: true)
    }

    static var dimissAndRefresh: NavigationConfiguration {
        NavigationConfiguration(dismissBeforeShowing: true, refresh: true)
    }

    static func dimissAndRefresh(with event: TelemetryEventType) -> NavigationConfiguration {
        NavigationConfiguration(dismissBeforeShowing: true, refresh: true, telemetryEvent: event)
    }
}

enum RouterDestination: Hashable {
    case urlPage(urlString: String)
    case openSettings
}

enum SheetDestination: Equatable, Hashable {
    case sharingFlow
    ///  The boolean helps to know if we should dismiss the previous sheet or not as the route if used in different
    /// context
    case manageShareVault(Vault, dismissBeforeShowing: Bool)
    case filterItems
    case acceptRejectInvite(UserInvite)
    case vaultCreateEdit(vault: Vault?)
    case upgradeFlow
    case logView(module: PassModule)
    case suffixView(SuffixSelection)
    case mailboxView(MailboxSelection, MailboxSection.Mode)
    case autoFillInstructions
    case moveItemsBetweenVaults(currentVault: Vault, singleItemToMove: ItemContent?)
}

enum UIElementDisplay {
    case globalLoading(shouldShow: Bool)
    case displayErrorBanner(Error)
    case successMessage(String, config: NavigationConfiguration)
}

final class MainUIKitSwiftUIRouter: Sendable {
    let newPresentationDestination: PassthroughSubject<RouterDestination, Never> = .init()
    let newSheetDestination: PassthroughSubject<SheetDestination, Never> = .init()
    let globalElementDisplay: PassthroughSubject<UIElementDisplay, Never> = .init()

    func navigate(to destination: RouterDestination) {
        newPresentationDestination.send(destination)
    }

    func present(for destination: SheetDestination) {
        newSheetDestination.send(destination)
    }

    func display(element: UIElementDisplay) {
        globalElementDisplay.send(element)
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
