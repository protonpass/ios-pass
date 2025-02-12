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
import Factory
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
    private let appVersion = resolve(\SharedToolingContainer.appVersion)
    private let doh = resolve(\SharedToolingContainer.doh)
    private let mainKeyProvider = resolve(\SharedToolingContainer.mainKeyProvider)
    private let featureFlagsRepository = resolve(\SharedRepositoryContainer.featureFlagsRepository)

    // Strongly reference to make the payment page responsive during payment flow
    // periphery:ignore
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
                guard let doh = doh as? ProtonPassDoH else {
                    return
                }
                try createPaymentsV2UI(hideCurrentPlan: isUpgrading, doh: doh, completion: completion)
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
}

// MARK: - Utils

private extension PaymentsManager {
    func setup() {
        userManager
            .currentActiveUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userData in
                guard let self else { return }
                if userData == nil {
                    transactionsObserver.stop()
                    return
                }

                guard let userData,
                      let doh = doh as? ProtonPassDoH
                else {
                    transactionsObserver.stop()
                    return
                }

                handleTransactionObserver(userData: userData, doh: doh)
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
                            doh: DoHInterface & ServerConfig,
                            completion: @escaping (Result<Bool, any Error>) -> Void) throws {
        guard let userData = userManager.currentActiveUser.value, let envString = doh as? ProtonPassDoH else {
            throw PassError.payments(.couldNotCreatePaymentStack)
        }

        let sessionID = userData.credential.sessionID
        let accessToken = userData.credential.accessToken

        try paymentsV2.showAvailablePlans(presentationMode: .modal,
                                          sessionID: sessionID,
                                          accessToken: accessToken,
                                          appVersion: appVersion,
                                          hideCurrentPlan: hideCurrentPlan,
                                          doh: doh)
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
                    paymentsV2.dismissPayments()
                case .mismatchTransactionIDs, .transactionProcessError, .unableToGetUserTransactionUUID,
                     .unknownError:
                    completion(.success(false)) // to be updated
                    paymentsV2.dismissPayments()
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
        }
    }

    func handleTransactionObserver(userData: UserData, doh: ProtonPassDoH) {
        let appVersion = appVersion
        let sessionID = userData.credential.sessionID
        let authToken = userData.credential.accessToken
        transactionTask?.cancel()
        transactionTask = Task { [weak self] in
            guard let self else { return }

            let configuration = TransactionsObserverConfiguration(sessionID: sessionID,
                                                                  authToken: authToken,
                                                                  appVersion: appVersion,
                                                                  doh: doh)

            transactionsObserver.setConfiguration(configuration)

            do {
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
