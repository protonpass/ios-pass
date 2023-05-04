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

    let isShownAsSheet: Bool
    let apiService: APIService
    let logger: Logger
    let theme: Theme
    let username: String
    let passPlanRepository: PassPlanRepositoryProtocol

    @Published private(set) var plan: PassPlan?

    weak var delegate: AccountViewModelDelegate?

    init(isShownAsSheet: Bool,
         apiService: APIService,
         logManager: LogManager,
         theme: Theme,
         username: String,
         passPlanRepository: PassPlanRepositoryProtocol) {
        self.isShownAsSheet = isShownAsSheet
        self.apiService = apiService
        self.logger = .init(manager: logManager)
        self.username = username
        self.theme = theme
        self.passPlanRepository = passPlanRepository

        Task { @MainActor in
            do {
                // First get local plan to optimistically display it
                // and then try to refresh the plan to have it updated
                plan = try await passPlanRepository.getPlan()
                plan = try await passPlanRepository.refreshPlan()
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
