//
// AccountViewModel.swift
// Proton Pass - Created on 30/03/2023.
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
import Core
import ProtonCore_Services

protocol AccountViewModelDelegate: AnyObject {
    func accountViewModelWantsToGoBack()
    func accountViewModelWantsToManageSubscription()
    func accountViewModelWantsToSignOut()
    func accountViewModelWantsToDeleteAccount()
}

final class AccountViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let apiService: APIService
    let logger: Logger
    let theme: Theme
    let username: String
    @Published private(set) var primaryPlan: PlanLite?

    weak var delegate: AccountViewModelDelegate?

    init(apiService: APIService,
         logManager: LogManager,
         primaryPlan: PlanLite?,
         theme: Theme,
         username: String) {
        self.apiService = apiService
        self.logger = .init(manager: logManager)
        self.username = username
        self.primaryPlan = primaryPlan
        self.theme = theme
        self.refreshOrganization()
    }

    private func refreshOrganization() {
        Task { @MainActor in
            do {
                logger.trace("Refreshing primary plan")
                let primaryPlan = try await PrimaryPlanProvider.getPrimaryPlan(apiService: apiService)
                if let primaryPlan {
                    self.primaryPlan = primaryPlan
                    logger.info("Refreshed primary plan")
                } else {
                    logger.info("Refreshed primary plan. User is not subscribed")
                }
            } catch {
                logger.error(error)
            }
        }
    }
}

extension AccountViewModel {
    func goBack() {
        delegate?.accountViewModelWantsToGoBack()
    }

    func manageSubscription() {
        delegate?.accountViewModelWantsToManageSubscription()
    }

    func signOut() {
        delegate?.accountViewModelWantsToSignOut()
    }

    func deleteAccount() {
        delegate?.accountViewModelWantsToDeleteAccount()
    }
}
