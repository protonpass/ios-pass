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

import DesignSystem
import Entities
import Screens
import SwiftUI

extension HomepageCoordinator {
    func refreshInAppNotifications() {
        guard inAppNotificationEnabled else {
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await inAppNotificationManager.fetchNotifications()
                if let notification = try await inAppNotificationManager.getNotificationToDisplay() {
                    displayNotification(notification)
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
}

// MARK: - Notification actions

private extension HomepageCoordinator {
    func displayNotification(_ notification: InAppNotification) {
        addTelemetryEvent(with: .notificationDisplayNotification(notificationKey: notification
                .notificationKey))

        switch notification.displayType {
        case .banner:
            let view = InAppBannerView(notification: notification,
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
            let view = InAppModalView(notification: notification,
                                      onTap: { [weak self] notification in
                                          guard let self else { return }
                                          ctaFlow(notification)
                                      }, onClose: { [weak self] notification in
                                          guard let self else { return }
                                          close(notification)
                                      })
            let viewController = UIHostingController(rootView: view)
            viewController.setDetentType(.custom(CGFloat(490)),
                                         parentViewController: rootViewController)
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
                addTelemetryEvent(with: .notificationChangeNotificationStatus(notificationKey: notification
                        .notificationKey,
                    notificationStatus: notification
                        .removedState.rawValue))
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
                addTelemetryEvent(with: .notificationNotificationCtaClick(notificationKey: notification
                        .notificationKey))
                try await inAppNotificationManager.updateNotificationState(notificationId: notification.id,
                                                                           newState: notification.removedState)

                if case let .externalNavigation(url) = notification.cta {
                    urlOpener.open(urlString: url)
                } else if case let .internalNavigation(url) = notification.cta {
                    let destination = InternalNavigationDestination.parse(urlString: url)
                    navigate(to: destination)
                }
            } catch {
                handle(error: error)
            }
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
                    try await vaultMembers(shareID: sharedId)
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

    func vaultMembers(shareID: String) async throws {
        guard let vault = try await shareRepository.getVault(shareId: shareID) else {
            return
        }
        router.present(for: .manageShareVault(vault, .none))
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

private extension [Breach] {
    // Example function to filter the most severe and latest unresolved breach
    var mostSevereAndLatest: Breach? {
        self.max {
            // Compare by severity first, then by createdAt if severities are equal
            if $0.severity == $1.severity {
                return $0.createdAt < $1.createdAt // Later createdAt is greater
            }
            return $0.severity < $1.severity // Higher severity is greater
        }
    }
}
