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

                let isActive = userManager.currentActiveUser.value?.user.ID == userId
                let multiAccounts = users.count > 1

                // Scenario 1: Only 1 user
                if !multiAccounts {
                    signOutSingleUser(user)
                    return
                }

                // Scenario 2: Sign out active user when multiple users
                if isActive {
                    try signOutActiveUser(userToSignOut: user, allUsers: users)
                    return
                }

                // Scenario 3: Sign out inactive user when multiple users
                if !isActive {
                    signOutInactive(user)
                    return
                }

                assertionFailure("Not known sign out scenario")
            } catch {
                handle(error: error)
            }
        }
    }

    func wipeAllDataAndSignoutActiveUser() {
        Task { [weak self] in
            guard let self else { return }
            await wipeAllData()
            eventLoop.stop()
            delegate?.homepageCoordinatorWantsToLogOut()
        }
    }
}

private extension HomepageCoordinator {
    /// Scenario 1: Only 1 user
    /// Do not care if the user is active or not
    /// Step 1: Revoke the session
    /// Step 2: Stop the event loop
    /// Step 3: Remove cached credentials
    /// Step 4: Remove all local data
    /// Step 5: Reset repositories' on-memory caches
    /// Step 6: Back to welcome screen
    func signOutSingleUser(_ userData: UserData) {
        let handler: () -> Void = { [weak self] in
            Task { [weak self] in
                guard let self else { return }
                await revokeCurrentSession()
                wipeAllDataAndSignoutActiveUser()
            }
        }
        let alert = signOutAlert(accountToSignOut: userData,
                                 accountToActivate: nil,
                                 onSignOut: handler)
        present(alert)
    }

    /// Scenario 2: Sign out active user when multiple users
    /// Step 1: Revoke the session
    /// Step 2: Stop the event loop
    /// Step 3: Remove cached credentials
    /// Step 4: Remove all local data
    /// Step 5: Activate to the latest inactive user
    /// Step 6: Reinit event loop with the new user
    /// Step 7: Reload items
    func signOutActiveUser(userToSignOut: UserData, allUsers: [UserData]) throws {
        let otherUsers = allUsers.filter { $0.user.ID != userToSignOut.user.ID }
        guard let accountToActivate = otherUsers.first else {
            throw PassError.userManager(.noInactiveUserFound)
        }
        let alert = signOutAlert(accountToSignOut: userToSignOut,
                                 accountToActivate: accountToActivate,
                                 onSignOut: { print(#function) })
        present(alert)
    }

    /// Sign out inactive user when multiple users
    /// Step 1: Revoke the session
    /// Step 2: Remove all local data
    /// Step 3: Remove cached credentials
    func signOutInactive(_ userData: UserData) {
        let alert = signOutAlert(accountToSignOut: userData,
                                 accountToActivate: nil,
                                 onSignOut: { print(#function) })
        present(alert)
    }

    func signOutAlert(accountToSignOut: UserData,
                      accountToActivate: UserData?,
                      onSignOut: @escaping () -> Void) -> UIAlertController {
        let signOut = #localized("Sign out")
        let message = if let accountToActivate {
            #localized("You will be switched to %@", accountToActivate.user.email ?? "")
        } else {
            #localized("Are you sure you want to sign out %@?", accountToSignOut.user.email ?? "")
        }
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
