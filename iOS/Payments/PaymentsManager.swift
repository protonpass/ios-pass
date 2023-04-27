//
// PaymentsManager.swift
// Proton Pass - Created on 26/04/2023.
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

import Core
import ProtonCore_Payments
import ProtonCore_PaymentsUI
import ProtonCore_Services

final class PaymentsManager {

    typealias PaymentsResult = Result<InAppPurchasePlan?, Error>

    private let appData: AppData
    private let mainKeyProvider: MainKeyProvider
    private let payments: Payments
    private var paymentsUI: PaymentsUI?
    private let logger: Logger
    private let inMemoryTokenStorage: PaymentTokenStorage

    // TODO: should we provide the actual BugAlertHandler?
    init(apiService: APIService,
         appData: AppData,
         mainKeyProvider: MainKeyProvider,
         logger: Logger,
         bugAlertHandler: BugAlertHandler = nil) {
        // TODO: should we use the disk storage instead?
        let inMemoryDataStorage = InMemoryServicePlanDataStorage()
        // TODO: should we use the disk storage instead?
        let inMemoryTokenStorage = InMemoryTokenStorage()

        let payments = Payments(inAppPurchaseIdentifiers: PaymentsConstants.inAppPurchaseIdentifiers,
                                apiService: apiService,
                                localStorage: inMemoryDataStorage,
                                reportBugAlertHandler: bugAlertHandler)
        self.appData = appData
        self.mainKeyProvider = mainKeyProvider
        self.inMemoryTokenStorage = inMemoryTokenStorage
        self.payments = payments
        self.logger = logger

        payments.storeKitManager.delegate = self

        initializePaymentsStack()
    }

    func createPaymentsUI() -> PaymentsUI {
        PaymentsUI(payments: payments,
                   clientApp: PaymentsConstants.clientApp,
                   shownPlanNames: PaymentsConstants.shownPlanNames)
    }

    private func initializePaymentsStack() {
        payments.planService.currentSubscriptionChangeDelegate = self
        payments.storeKitManager.delegate = self
        payments.storeKitManager.updateAvailableProductsList { [weak self] error in
            self?.payments.storeKitManager.subscribeToPaymentQueue()
        }
    }

    func manageSubscription(completion: @escaping (Result<InAppPurchasePlan?, Error>) -> Void) {
        let paymentsUI = createPaymentsUI()
        // keep reference to avoid being deallocated
        self.paymentsUI = paymentsUI
        paymentsUI.showCurrentPlan(presentationType: .modal, backendFetch: true) { [weak self] result in
            self?.handlePaymentsResponse(result: result, completion: completion)
        }
    }

    func upgradeSubscription(completion: @escaping (Result<InAppPurchasePlan?, Error>) -> Void) {
        let paymentsUI = createPaymentsUI()
        // keep reference to avoid being deallocated
        self.paymentsUI = paymentsUI
        paymentsUI.showUpgradePlan(presentationType: .modal, backendFetch: true) { [weak self] result in
            self?.handlePaymentsResponse(result: result, completion: completion)
        }
    }

    private func handlePaymentsResponse(result: PaymentsUIResultReason,
                                        completion: @escaping (Result<InAppPurchasePlan?, Error>) -> Void) {
        switch result {
        case let .purchasedPlan(accountPlan: plan):
            self.logger.trace("Purchased plan: \(plan.protonName)")
            completion(.success(plan))
        case let .open(vc: _, opened: opened):
            assert(opened == true)
        case let .planPurchaseProcessingInProgress(accountPlan: plan):
            self.logger.trace("Purchasing \(plan.protonName)")
        case .close:
            self.logger.trace("Payments closed")
            completion(.success(nil))
        case let .purchaseError(error: error):
            self.logger.trace("Purchase failed with error \(error)")
            completion(.failure(error))
        case .toppedUpCredits:
            self.logger.trace("Credits topped up")
            completion(.success(nil))
        case let .apiMightBeBlocked(message, originalError: error):
            self.logger.trace("\(message), error \(error)")
            completion(.failure(error))
        }
    }
}

extension PaymentsManager: StoreKitManagerDelegate {
    var tokenStorage: PaymentTokenStorage? {
        inMemoryTokenStorage
    }

    var isUnlocked: Bool {
        // TODO: verify the implementation
        guard let mainKey = mainKeyProvider.mainKey, !mainKey.isEmpty else {
            return false
        }
        return true
    }

    var isSignedIn: Bool {
        guard let userData = appData.userData,
              !userData.getCredential.isForUnauthenticatedSession else {
            return false
        }
        return true
    }

    var activeUsername: String? {
        guard let userData = appData.userData else { return nil }
        return userData.user.name
    }

    var userId: String? {
        guard let userData = appData.userData else { return nil }
        return userData.user.ID
    }
}

extension PaymentsManager: CurrentSubscriptionChangeDelegate {
    func onCurrentSubscriptionChange(old: Subscription?, new: Subscription?) {
        // Nothing to do here for now, I guess?
    }
}
