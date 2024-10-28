//
// HomepageCoordinator+ManageAccount.swift
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
@preconcurrency import ProtonCoreLogin
import UIKit

extension HomepageCoordinator {
    func handleManageAccount(userId: String) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let users = try await userManager.getAllUsers()
                guard let user = users.first(where: { $0.user.ID == userId }) else {
                    throw PassError.userManager(.noUserDataFound)
                }

                let isActive = userManager.currentActiveUser.value?.user.ID == userId
                if isActive {
                    showAccountMenu()
                } else {
                    alertSwitchToManage(user)
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func showAccountMenu() {
        let asSheet = shouldShowAsSheet()
        let viewModel = AccountViewModel(isShownAsSheet: asSheet)
        viewModel.delegate = self
        let view = AccountView(viewModel: viewModel)
        showView(view: view, asSheet: asSheet)
    }
}

private extension HomepageCoordinator {
    func alertSwitchToManage(_ userData: UserData) {
        let message = #localized("You need to switch to %@ in order to manage it", userData.user.email ?? "")
        let alert = UIAlertController(title: #localized("Manage account"),
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(.init(title: #localized("Switch and manage"),
                              style: .default,
                              handler: { [weak self] _ in
                                  guard let self else {
                                      return
                                  }
                                  Task { [weak self] in
                                      guard let self else {
                                          return
                                      }
                                      do {
                                          let userId = userData.user.ID
                                          try await switchUser(userId: userId)
                                          handleManageAccount(userId: userId)
                                      } catch {
                                          handle(error: error)
                                      }
                                  }
                              }))
        alert.addAction(.init(title: #localized("Cancel"), style: .cancel))
        present(alert)
    }
}
