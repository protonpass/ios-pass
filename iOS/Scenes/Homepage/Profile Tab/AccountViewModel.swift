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
    let userPlanProvider: UserPlanProviderProtocol
    @Published private(set) var userPlan: UserPlan?

    weak var delegate: AccountViewModelDelegate?

    var planName: String? {
        switch userPlan {
        case .none:
            return nil
        case .some(let wrapped):
            switch wrapped {
            case .free:
                return "Free"
            case .paid(let plan):
                return plan.title
            case .subUser:
                return nil
            }
        }
    }

    init(isShownAsSheet: Bool,
         apiService: APIService,
         logManager: LogManager,
         theme: Theme,
         username: String,
         userPlan: UserPlan?,
         userPlanProvider: UserPlanProviderProtocol) {
        self.isShownAsSheet = isShownAsSheet
        self.apiService = apiService
        self.logger = .init(manager: logManager)
        self.username = username
        self.theme = theme
        self.userPlan = userPlan
        self.userPlanProvider = userPlanProvider
        self.refreshOrganization()
    }

    private func refreshOrganization() {
        Task { @MainActor in
            do {
                userPlan = try await userPlanProvider.getUserPlan()
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
