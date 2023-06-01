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

    private let userDataProvider: UserDataProvider
    private let mainKeyProvider: MainKeyProvider
    private let payments: Payments
    private var paymentsUI: PaymentsUI?
    private let logger: Logger
    private let preferences: Preferences
    private let inMemoryTokenStorage: PaymentTokenStorage

    // swiftlint:disable:next todo
    // TODO: should we provide the actual BugAlertHandler?
    init(apiService: APIService,
         userDataProvider: UserDataProvider,
         mainKeyProvider: MainKeyProvider,
         logger: Logger,
         preferences: Preferences,
         storage: UserDefaults,
         bugAlertHandler: BugAlertHandler = nil) {
        let persistentDataStorage = UserDefaultsServicePlanDataStorage(storage: storage)
        let inMemoryTokenStorage = InMemoryTokenStorage()

        let payments = Payments(inAppPurchaseIdentifiers: PaymentsConstants.inAppPurchaseIdentifiers,
                                apiService: apiService,
                                localStorage: persistentDataStorage,
                                reportBugAlertHandler: bugAlertHandler)
        self.userDataProvider = userDataProvider
        self.mainKeyProvider = mainKeyProvider
        self.inMemoryTokenStorage = inMemoryTokenStorage
        self.payments = payments
        self.logger = logger
        self.preferences = preferences

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
        payments.storeKitManager.updateAvailableProductsList { [weak self] _ in
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
        case let .open(viewController, opened):
            assert(opened == true)
            viewController.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
            viewController.navigationController?.overrideUserInterfaceStyle = preferences.theme.userInterfaceStyle
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
        mainKeyProvider.mainKey?.isEmpty == false
    }

    var isSignedIn: Bool {
        userDataProvider.userData?.getCredential.isForUnauthenticatedSession == false
    }

    var activeUsername: String? {
        userDataProvider.userData?.user.name
    }

    var userId: String? {
        userDataProvider.userData?.user.ID
    }
}

extension PaymentsManager: CurrentSubscriptionChangeDelegate {
    func onCurrentSubscriptionChange(old: Subscription?, new: Subscription?) {
        // Nothing to do here for now, I guess?
    }
}
