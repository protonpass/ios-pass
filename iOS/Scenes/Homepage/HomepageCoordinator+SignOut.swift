//
// HomepageCoordinator+SignOut.swift
// Proton Pass - Created on 04/07/2024.
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

import Entities
import Macro
import ProtonCoreLogin
import UIKit

extension HomepageCoordinator {
    func handleSignOut(userId: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let users = try await userManager.getAllUsers()
                guard let user = users.first(where: { $0.user.ID == userId }) else {
                    throw PassError.userManager(.noUserDataFound)
                }

                let handler: () -> Void = { [weak self] in
                    guard let self else { return }
                    dismissAllViewControllers { [weak self] in
                        guard let self else {
                            return
                        }
                        showLoadingHud()
                        loggingOutUser(userId: userId)
                        hideLoadingHud()
                    }
                }

                let alert = signOutAlert(accountToSignOut: user,
                                         onSignOut: handler)
                present(alert)
            } catch {
                handle(error: error)
            }
        }
    }

    func loggingOutUser(userId: String) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                if userManager.allUserAccounts.value.count > 1 {
                    addTelemetryEvent(with: .multiAccountRemoveAccount)
                }
                if try await logOutUser(userId: userId) {
                    /// Reset `appCoverView` when logging out from the last account
                    /// because `appCoverView` is attached to the window level which outlives `HomepageCoordinator`
                    /// Which stucks users on local auth screen when logging out & in without closing the app
                    /// (`HomepageCoordinator` is destroyed when logging out from the last account.
                    /// Left over `appCoverView`, which is attached to a destroyed `HomepageCoordinator`
                    /// unable to uncover the app when local auth succeeds)
                    appCoverView?.removeFromSuperview()
                    appCoverView = nil
                    delegate?.homepageCoordinatorWantsToLogOut()
                }
            } catch {
                bannerManager
                    .displayTopErrorMessage(error.localizedDescription)
            }
        }
    }
}

private extension HomepageCoordinator {
    func signOutAlert(accountToSignOut: UserData,
                      onSignOut: @escaping () -> Void) -> UIAlertController {
        let signOut = #localized("Sign out")
        let message = #localized("Are you sure you want to sign out %@?", accountToSignOut.user.email ?? "")
        // Show as alert on iPad because action sheets on iPad are considered a popover
        // which requires additional set up otherwise it will crash
        let alert = UIAlertController(title: signOut,
                                      message: message,
                                      preferredStyle: UIDevice.current.isIpad ? .alert : .actionSheet)
        alert.addAction(.init(title: signOut,
                              style: .destructive,
                              handler: { _ in onSignOut() }))
        alert.addAction(.init(title: #localized("Cancel"), style: .cancel))
        return alert
    }
}
