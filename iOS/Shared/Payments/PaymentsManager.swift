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
import Factory
import Foundation
import ProtonCoreFeatureFlags
import ProtonCorePayments
import ProtonCorePaymentsUI

final class PaymentsManager {
    typealias PaymentsResult = Result<InAppPurchasePlan?, any Error>

    private let apiManager = resolve(\SharedToolingContainer.apiManager)
    private let appData = resolve(\SharedDataContainer.appData)
    private let userManager = resolve(\SharedServiceContainer.userManager)
    private let authManager = resolve(\SharedToolingContainer.authManager)

    private let mainKeyProvider = resolve(\SharedToolingContainer.mainKeyProvider)
    private let featureFlagsRepository = resolve(\SharedRepositoryContainer.featureFlagsRepository)
    private let payments: Payments

    // Strongly reference to make the payment page responsive during payment flow
    // periphery:ignore
    private var paymentsUI: PaymentsUI?
    private let logger = resolve(\SharedToolingContainer.logger)
    private let theme = resolve(\SharedToolingContainer.theme)
    private let inMemoryTokenStorage: any PaymentTokenStorage

    // swiftlint:disable:next todo
    // TODO: should we provide the actual BugAlertHandler?
    init(storage: UserDefaults,
         bugAlertHandler: BugAlertHandler = nil) {
        inMemoryTokenStorage = InMemoryTokenStorage()
        let persistentDataStorage = UserDefaultsServicePlanDataStorage(storage: storage)
        let payments = Payments(inAppPurchaseIdentifiers: PaymentsConstants.inAppPurchaseIdentifiers,
                                apiService: apiManager.apiService,
                                localStorage: persistentDataStorage,
                                reportBugAlertHandler: bugAlertHandler)
        self.payments = payments
        payments.storeKitManager.delegate = self
        initializePaymentsStack()
    }

    func createPaymentsUI() -> PaymentsUI {
        let ui = PaymentsUI(payments: payments,
                            clientApp: PaymentsConstants.clientApp,
                            shownPlanNames: PaymentsConstants.shownPlanNames,
                            customization: .init(inAppTheme: { [theme] in theme.inAppTheme }))
        paymentsUI = ui
        return ui
    }

    private func initializePaymentsStack() {
        switch payments.planService {
        case let .left(service):
            service.currentSubscriptionChangeDelegate = self
        default:
            break
        }

        payments.storeKitManager.delegate = self

        if !featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan) {
            payments.storeKitManager.updateAvailableProductsList { [weak self] _ in
                guard let self else { return }
                payments.storeKitManager.subscribeToPaymentQueue()
            }
        } else {
            payments.storeKitManager.subscribeToPaymentQueue()
        }
    }

    func manageSubscription(completion: @escaping (Result<InAppPurchasePlan?, any Error>) -> Void) {
        guard !Bundle.main.isBetaBuild else { return }

        let paymentsUI = createPaymentsUI()
        paymentsUI.showCurrentPlan(presentationType: .modal, backendFetch: true) { [weak self] result in
            guard let self else { return }
            handlePaymentsResponse(result: result, completion: completion)
        }
    }

    func upgradeSubscription(completion: @escaping (Result<InAppPurchasePlan?, any Error>) -> Void) {
        guard !Bundle.main.isBetaBuild else { return }

        let paymentsUI = createPaymentsUI()

        paymentsUI.showUpgradePlan(presentationType: .modal, backendFetch: true) { [weak self] reason in
            guard let self else { return }
            handlePaymentsResponse(result: reason, completion: completion)
        }
    }

    private func handlePaymentsResponse(result: PaymentsUIResultReason,
                                        completion: @escaping (Result<InAppPurchasePlan?, any Error>) -> Void) {
        switch result {
        case let .purchasedPlan(accountPlan: plan):
            logger.trace("Purchased plan: \(plan.protonName)")
            completion(.success(plan))
        case .open:
            break
        case let .planPurchaseProcessingInProgress(accountPlan: plan):
            logger.trace("Purchasing \(plan.protonName)")
        case .close:
            logger.trace("Payments closed")
            completion(.success(nil))
        case let .purchaseError(error: error):
            logger.trace("Purchase failed with error \(error)")
            completion(.failure(error))
        case .toppedUpCredits:
            logger.trace("Credits topped up")
            completion(.success(nil))
        case let .apiMightBeBlocked(message, originalError: error):
            logger.trace("\(message), error \(error)")
            completion(.failure(error))
        }
    }
}

extension PaymentsManager: StoreKitManagerDelegate {
    var tokenStorage: (any PaymentTokenStorage)? {
        inMemoryTokenStorage
    }

    var isUnlocked: Bool {
        mainKeyProvider.mainKey?.isEmpty == false
    }

    var isSignedIn: Bool {
        guard let activeUserId = userManager.activeUserId else {
            return false
        }
        return authManager.isAuthenticated(userId: activeUserId)
//        appData.isAuthenticated
    }

    var activeUsername: String? {
        userManager.currentActiveUser.value?.user.name
    }

    var userId: String? {
        userManager.currentActiveUser.value?.user.ID
    }
}

extension PaymentsManager: CurrentSubscriptionChangeDelegate {
    func onCurrentSubscriptionChange(old: Subscription?, new: Subscription?) {
        // Nothing to do here for now, I guess?
    }
}
