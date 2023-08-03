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
import Factory

protocol AccountViewModelDelegate: AnyObject {
    func accountViewModelWantsToGoBack()
    func accountViewModelWantsToSignOut()
    func accountViewModelWantsToDeleteAccount()
}

final class AccountViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let passPlanRepository = resolve(\SharedRepositoryContainer.passPlanRepository)
    private let userData = resolve(\SharedDataContainer.userData)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let paymentsManager = resolve(\ServiceContainer.paymentManager)
    let isShownAsSheet: Bool
    @Published private(set) var plan: PassPlan?

    weak var delegate: AccountViewModelDelegate?

    var username: String { userData.user.email ?? "" }

    init(isShownAsSheet: Bool) {
        self.isShownAsSheet = isShownAsSheet
        refreshUserPlan()
    }

    private func refreshUserPlan() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                // First get local plan to optimistically display it
                // and then try to refresh the plan to have it updated
                self.plan = try await self.passPlanRepository.getPlan()
                self.plan = try await self.passPlanRepository.refreshPlan()
            } catch {
                self.logger.error(error)
            }
        }
    }
}

extension AccountViewModel {
    func goBack() {
        delegate?.accountViewModelWantsToGoBack()
    }

    func manageSubscription() {
        paymentsManager.manageSubscription { [weak self] result in
            self?.handlePaymentsResult(result: result)
        }
    }

    func upgradeSubscription() {
        paymentsManager.upgradeSubscription { [weak self] result in
            self?.handlePaymentsResult(result: result)
        }
    }

    private func handlePaymentsResult(result: PaymentsManager.PaymentsResult) {
        switch result {
        case let .success(inAppPurchasePlan):
            if inAppPurchasePlan != nil {
                refreshUserPlan()
            } else {
                logger.debug("Payment is done but no plan is purchased")
            }

        case let .failure(error):
            logger.error(error)
        }
    }

    func signOut() {
        delegate?.accountViewModelWantsToSignOut()
    }

    func deleteAccount() {
        delegate?.accountViewModelWantsToDeleteAccount()
    }
}
