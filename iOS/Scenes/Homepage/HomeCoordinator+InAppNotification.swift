//
// HomeCoordinator+InAppNotification.swift
// Proton Pass - Created on 07/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import DesignSystem
import Entities
import Screens
import SwiftUI

extension HomepageCoordinator {
    func refreshInAppNotifications() {
        guard authenticated else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await inAppNotificationManager.fetchNotifications()
                if let notification = try await inAppNotificationManager.getNotificationToDisplay() {
                    itemsTabViewModel?.displayedNotification = notification
                    display(notification)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func presentBreachDetail(breach: Breach) {
        present(BreachDetailView(breach: breach))
    }

    func presentBreach(breach: BreachDetailsInfo) {
        present(DetailMonitoredItemView(viewModel: .init(infos: breach)))
    }

    func removeInAppNotificationDisplay() {
        updateFloatingView(floatingView: nil, viewTag: UniqueSheet.inAppNotificationDisplay)
        dismissViewControllerWithTag(tag: UniqueSheet.inAppNotificationDisplay)
    }

    func display(_ notification: InAppNotification) {
        display(notification,
                onAppear: { [weak self] in
                    guard let self else { return }
                    updateDisplayState(.active)
                },
                onDisappear: { [weak self] in
                    guard let self else { return }
                    updateDisplayState(.inactive)
                })
    }
}

// MARK: - Notification actions

private extension HomepageCoordinator {
    func display(_ notification: InAppNotification,
                 onAppear: @escaping () -> Void,
                 onDisappear: @escaping () -> Void) {
        // Do not display in-app notification if there's currently another sheet
        guard rootViewController.presentedViewController == nil else { return }
        addTelemetryEvent(with: .notificationDisplay(key: notification.notificationKey))

        switch notification.displayType {
        case .banner:
            let view = InAppBannerView(notification: notification,
                                       onAppear: onAppear,
                                       onDisappear: onDisappear,
                                       onTap: { [weak self] notification in
                                           guard let self else { return }
                                           ctaFlow(notification)
                                       },
                                       onClose: { [weak self] notification in
                                           guard let self else { return }
                                           close(notification)
                                       })
            let viewController = UIHostingController(rootView: view)
            if let view = viewController.view {
                updateFloatingView(floatingView: view, viewTag: UniqueSheet.inAppNotificationDisplay)
            }

        case .modal:
            let viewModel = InAppModalViewModel()
            let view = InAppModalView(notification: notification,
                                      viewModel: viewModel,
                                      onAppear: onAppear,
                                      onDisappear: onDisappear,
                                      onTap: { [weak self] notification in
                                          guard let self else { return }
                                          ctaFlow(notification)
                                      }, onClose: { [weak self] notification in
                                          guard let self else { return }
                                          close(notification)
                                      })
            let viewController = UIHostingController(rootView: view)
            viewController.setDetentType(.medium,
                                         parentViewController: rootViewController)
            viewModel.sheetPresentation = viewController.sheetPresentationController
            present(viewController, uniquenessTag: UniqueSheet.inAppNotificationDisplay)

        case .promo:
            guard let promoContents = notification.content.promoContents else {
                assertionFailure("Promo contents not exist")
                return
            }
            let view = InAppPromoView(notification: notification,
                                      promoContents: promoContents,
                                      onAppear: onAppear,
                                      onMinimize: {
                                          onDisappear()
                                      },
                                      onDismiss: {
                                          onDisappear()
                                      })
            let viewController = UIHostingController(rootView: view)
            viewController.modalPresentationStyle = UIDevice.current.isIpad ? .formSheet : .fullScreen
            present(viewController, uniquenessTag: UniqueSheet.inAppNotificationDisplay)
        }
    }

    func close(_ notification: InAppNotification) {
        Task { [weak self] in
            guard let self else { return }
            if notification.displayType == .banner {
                updateFloatingView(floatingView: nil, viewTag: UniqueSheet.inAppNotificationDisplay)
            }
            do {
                try await inAppNotificationManager.updateNotificationState(notificationId: notification.id,
                                                                           newState: notification.removedState)
                try await inAppNotificationManager.updateNotificationTime(.now)
                let key = notification.notificationKey
                let status = notification.removedState.rawValue
                addTelemetryEvent(with: .notificationChangeStatus(key: key, status: status))
            } catch {
                logger.error(error)
            }
        }
    }

    func ctaFlow(_ notification: InAppNotification) {
        Task { [weak self] in
            guard let self else { return }
            do {
                if notification.displayType == .banner {
                    updateFloatingView(floatingView: nil, viewTag: UniqueSheet.inAppNotificationDisplay)
                }
                addTelemetryEvent(with: .notificationCtaClick(key: notification.notificationKey))
                try await inAppNotificationManager.updateNotificationState(notificationId: notification.id,
                                                                           newState: notification.removedState)
                try await inAppNotificationManager.updateNotificationTime(.now)
                if case let .externalNavigation(url) = notification.ctaType {
                    urlOpener.open(urlString: url)
                } else if case let .internalNavigation(url) = notification.ctaType {
                    let destination = InternalNavigationDestination.parse(urlString: url)
                    navigate(to: destination)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func updateDisplayState(_ state: InAppNotificationDisplayState) {
        Task { [weak self] in
            guard let self else { return }
            await inAppNotificationManager.updateDisplayState(state)
        }
    }
}

// MARK: - In app navigation

private extension HomepageCoordinator {
    func navigate(to destination: InternalNavigationDestination) {
        Task {
            do {
                switch destination {
                case let .viewVaultMembers(sharedId):
                    try await shareMembers(shareID: sharedId)
                case let .aliasBreach(sharedId, itemId):
                    try await aliasBreach(shareID: sharedId, itemID: itemId)
                case let .customEmailBreach(customEmailId):
                    try await customEmailBreach(customEmailId: customEmailId)
                case let .addressBreach(addressID):
                    try await protonAddressBreach(protonAddressId: addressID)
                case .upgrade:
                    router.present(for: .upgradeFlow)
                case let .viewItem(shareID, itemID):
                    try await itemDetail(shareID: shareID, itemID: itemID)
                case .aliasManagement:
                    router.present(for: .aliasesSyncConfiguration)
                case let .unknown(url):
                    logger.trace("Unknown navigation destination: \(url)")
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func itemDetail(shareID: String, itemID: String) async throws {
        guard let itemContent = try await itemRepository.getItemContent(shareId: shareID, itemId: itemID) else {
            return
        }
        router.present(for: .itemDetail(itemContent))
    }

    func shareMembers(shareID: String) async throws {
        guard let vault = try await shareRepository.getDecryptedShare(shareId: shareID) else {
            return
        }
        router.present(for: .manageSharedShare(.vault(vault), .none))
    }

    func aliasBreach(shareID: String, itemID: String) async throws {
        guard let alias = try await itemRepository.getItemContent(shareId: shareID, itemId: itemID) else {
            return
        }
        let breaches = try await passMonitorRepository.getBreachesForAlias(sharedId: shareID,
                                                                           itemId: itemID)
        let aliasMonitorInfo = AliasMonitorInfo(alias: alias, breaches: breaches)
        router.present(for: .breach(.alias(aliasMonitorInfo)))
    }

    func customEmailBreach(customEmailId: String) async throws {
        let breaches = try await passMonitorRepository
            .refreshUserBreaches() // getAllBreachesForEmail(emailId: customEmail)
        guard let breach = breaches.customEmails.first(where: { $0.customEmailID == customEmailId }) else {
            return
        }
        router.present(for: .breach(.customEmail(breach)))
    }

    func protonAddressBreach(protonAddressId: String) async throws {
        let breaches = try await passMonitorRepository.refreshUserBreaches()
        guard let breach = breaches.addresses.first(where: { $0.addressID == protonAddressId }) else {
            return
        }
        router.present(for: .breach(.protonAddress(breach)))
    }
}
