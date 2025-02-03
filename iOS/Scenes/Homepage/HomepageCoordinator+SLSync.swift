//
// HomepageCoordinator+SLSync.swift
// Proton Pass - Created on 23/01/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Entities
import Screens
import SwiftUI

extension HomepageCoordinator {
    func suggestSimpleLoginSyncIfApplicable() async throws {
        do {
            guard !preferencesManager.appPreferences.unwrapped().dismissedAliasesSyncExplanation,
                  getFeatureFlagStatus(for: FeatureFlagType.passSimpleLoginAliasesSync),
                  let count = try await getPendingAliasCount() else {
                return
            }

            var vc: UIViewController?
            let view = AliasSyncView(count: count,
                                     onDismiss: { [weak self] in
                                         guard let self else { return }
                                         dismissAliasesSyncExplanation(viewController: vc)
                                     },
                                     onSync: { [weak self] in
                                         guard let self else { return }
                                         router.present(for: .simpleLoginSyncActivation(dismissAllSheets: true))
                                     })
            vc = UIHostingController(rootView: view)
            vc?.sheetPresentationController?.detents = [.medium()]
            if let vc, rootViewController.presentedViewController == nil {
                present(vc, dismissible: false)
            }
        } catch {
            handle(error: error)
        }
    }
}

private extension HomepageCoordinator {
    func getPendingAliasCount() async throws -> Int? {
        let userId = try await userManager.getActiveUserId()
        let userAccess: UserAccess = if let access = accessRepository.access.value {
            access
        } else {
            try await accessRepository.refreshAccess(userId: userId)
        }
        guard !userAccess.access.userData.aliasSyncEnabled else { return nil }

        let number = try await aliasRepository.getAliasSyncStatus(userId: userId).pendingAliasCount
        return number > 0 ? number : nil
    }

    func dismissAliasesSyncExplanation(viewController: UIViewController?) {
        Task { [weak self] in
            guard let self else { return }
            do {
                viewController?.dismiss(animated: true)
                try await preferencesManager.updateAppPreferences(\.dismissedAliasesSyncExplanation,
                                                                  value: true)
            } catch {
                handle(error: error)
            }
        }
    }
}
