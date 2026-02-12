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

@preconcurrency import Client
import Combine
import Core
import Entities
import FactoryKit
import Foundation
@preconcurrency import ProtonCoreDoh
import ProtonCoreFeatureFlags
import ProtonCoreLogin
@preconcurrency import ProtonCorePayments
import ProtonCorePaymentsUI
import ProtonCorePaymentsUIV2
import ProtonCorePaymentsV2

final class PaymentsManager: Sendable {
    typealias PaymentsResult = Result<Bool, any Error>

    private let apiManager = resolve(\SharedToolingContainer.apiManager)
    private let userManager = resolve(\SharedServiceContainer.userManager)
    private let authManager = resolve(\SharedToolingContainer.authManager)
    private let mainKeyProvider = resolve(\SharedToolingContainer.mainKeyProvider)
    private let featureFlagsRepository = resolve(\SharedRepositoryContainer.featureFlagsRepository)

    // Strongly reference to make the payment page responsive during payment flow
    private nonisolated(unsafe) var paymentsUI: PaymentsUI?
    private let logger = resolve(\SharedToolingContainer.logger)
    private let theme = resolve(\SharedToolingContainer.theme)
    private let inMemoryTokenStorage: any PaymentTokenStorage
    private let storage: UserDefaults
    private let paymentsV2 = PaymentsV2()

    private nonisolated(unsafe) var cancellables: Set<AnyCancellable> = []

    private let transactionsObserver: any TransactionsObserverProviding
    private nonisolated(unsafe) var transactionTask: Task<Void, Never>?

    init(storage: UserDefaults,
         transactionsObserver: any TransactionsObserverProviding = TransactionsObserver.shared) {
        inMemoryTokenStorage = InMemoryTokenStorage()
        self.storage = storage
        self.transactionsObserver = transactionsObserver
        setup()
    }

    @MainActor
    func manageSubscription(isUpgrading: Bool,
                            completion: @escaping (Result<Bool, any Error>) -> Void) {
        guard !Bundle.main.isBetaBuild else {
            return
        }
        do {
            if featureFlagsRepository.isEnabled(CoreFeatureFlagType.paymentsV2) {
                try createPaymentsV2UI(hideCurrentPlan: isUpgrading, completion: completion)
            } else {
                let paymentsUI = try createPaymentsUI()
                if isUpgrading {
                    paymentsUI
                        .showUpgradePlan(presentationType: .modal, backendFetch: true) { [weak self] reason in
                            guard let self else { return }
                            handlePaymentsResponse(result: reason, completion: completion)
                        }
                } else {
                    paymentsUI
                        .showCurrentPlan(presentationType: .modal, backendFetch: true) { [weak self] result in
                            guard let self else { return }
                            handlePaymentsResponse(result: result, completion: completion)
                        }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func restorePurchases() async throws {
        guard !Bundle.main.isBetaBuild,
              featureFlagsRepository.isEnabled(CoreFeatureFlagType.paymentsV2) else { return }
        let userID = try await userManager.getActiveUserId()
        let apiService = try apiManager.getApiService(userId: userID)
        _ = try await paymentsV2.restorePurchases(apiService: apiService)
    }
}

// MARK: - Utils

private extension PaymentsManager {
    func setup() {
        userManager
            .currentActiveUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userData in
                guard let self else { return }
                guard let userData else {
                    transactionsObserver.stop()
                    return
                }

                handleTransactionObserver(userData: userData)
            }
            .store(in: &cancellables)
    }

    func createPaymentsUI() throws -> PaymentsUI {
        let payments = try initializePaymentsStack()
        let ui = PaymentsUI(payments: payments,
                            clientApp: PaymentsConstants.clientApp,
                            shownPlanNames: PaymentsConstants.shownPlanNames,
                            customization: .init(inAppTheme: { [theme] in theme.inAppTheme }))
        paymentsUI = ui
        return ui
    }

    func createPaymentsV2UI(hideCurrentPlan: Bool = false,
                            completion: @escaping (Result<Bool, any Error>) -> Void) throws {
        guard let userData = userManager.currentActiveUser.value else {
            throw PassError.payments(.couldNotCreatePaymentStack)
        }

        let apiService = try apiManager.getApiService(userId: userData.user.ID)

        try paymentsV2.showAvailablePlans(presentationMode: .modal,
                                          hideCurrentPlan: hideCurrentPlan,
                                          apiService: apiService)
        paymentsV2.transactionProgress
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else { return }
                switch value {
                case .transactionCompleted:
                    completion(.success(true))
                    paymentsV2.dismissPayments()
                case .transactionCancelledByUser:
                    completion(.success(false)) // to be updated
                case .mismatchTransactionIDs, .transactionProcessError, .unableToGetUserTransactionUUID,
                     .unknownError:
                    completion(.success(false)) // to be updated
                default:
                    debugPrint("\(value) not handled")
                }
            }
            .store(in: &cancellables)
    }

    func initializePaymentsStack() throws -> Payments {
        guard let userId = userManager.activeUserId,
              let apiService = try? apiManager.getApiService(userId: userId) else {
            throw PassError.payments(.couldNotCreatePaymentStack)
        }
        let persistentDataStorage = UserDefaultsServicePlanDataStorage(storage: storage)

        let payments = Payments(inAppPurchaseIdentifiers: PaymentsConstants.inAppPurchaseIdentifiers,
                                apiService: apiService,
                                localStorage: persistentDataStorage,
                                reportBugAlertHandler: nil)

        switch payments.planService {
        case let .left(service):
            service.currentSubscriptionChangeDelegate = self
        default:
            break
        }

        payments.storeKitManager.delegate = self

        if !featureFlagsRepository.isEnabled(CoreFeatureFlagType.dynamicPlan) {
            payments.storeKitManager.updateAvailableProductsList { _ in
                payments.storeKitManager.subscribeToPaymentQueue()
            }
        } else {
            payments.storeKitManager.subscribeToPaymentQueue()
        }
        return payments
    }

    func handlePaymentsResponse(result: PaymentsUIResultReason,
                                completion: @escaping (Result<Bool, any Error>) -> Void) {
        switch result {
        case let .purchasedPlan(accountPlan: plan):
            logger.trace("Purchased plan: \(plan.protonName)")
            completion(.success(true))
        case .open:
            break
        case let .planPurchaseProcessingInProgress(accountPlan: plan):
            logger.trace("Purchasing \(plan.protonName)")
        case .close:
            logger.trace("Payments closed")
            completion(.success(true))
        case let .purchaseError(error: error):
            logger.trace("Purchase failed with error \(error)")
            completion(.failure(error))
        case .toppedUpCredits:
            logger.trace("Credits topped up")
            completion(.success(true))
        case let .apiMightBeBlocked(message, originalError: error):
            logger.trace("\(message), error \(error)")
            completion(.failure(error))
        case let .planAlreadyPurchased(error: error):
            logger.trace("Purchase failed with error \(error)")
            completion(.failure(error))
        }
    }

    func handleTransactionObserver(userData: UserData) {
        let userId = userData.user.ID

        transactionTask?.cancel()
        transactionTask = Task { [weak self] in
            guard let self else { return }
            do {
                let apiService = try apiManager.getApiService(userId: userId)
                let remoteManager = RemoteManager(apiService: apiService)

                let configuration = TransactionsObserverConfiguration(remoteManager: remoteManager)

                transactionsObserver.setConfiguration(configuration)
                try await transactionsObserver.start()
            } catch {
                logger.error(error)
            }
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
    }

    var activeUsername: String? {
        userManager.currentActiveUser.value?.user.name
    }

    var userId: String? {
        userManager.currentActiveUser.value?.user.ID
    }
}

extension PaymentsManager: CurrentSubscriptionChangeDelegate {
    func onCurrentSubscriptionChange(old: ProtonCorePayments.Subscription?,
                                     new: ProtonCorePayments.Subscription?) {
        // Nothing to do here for now, I guess?
    }
}
