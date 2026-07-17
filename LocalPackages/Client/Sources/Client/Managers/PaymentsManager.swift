//
// PaymentsManager.swift
// Proton Pass - Created on 07/07/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Entities
import Foundation
import ProtonCoreLogin
import ProtonCorePayments
import ProtonCorePaymentsUIV2
import ProtonCorePaymentsV2

public protocol PaymentsManagerProtocol {
    func manageSubscription(isUpgrading: Bool) async throws -> Bool
    func restorePurchases() async throws
}

@MainActor
public final class PaymentsManager: PaymentsManagerProtocol {
    private let apiManager: any APIManagerProtocol
    private let userManager: any UserManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let mainKeyProvider: any MainKeyProvider
    private let logger: Logger
    private nonisolated let inMemoryTokenStorage: InMemoryTokenStorage
    private let paymentsV2: PaymentsV2
    private let transactionsObserver: any TransactionsObserverProviding

    private var paymentFlow: Task<Bool, any Error>?
    private var userObservation: Task<Void, Never>?
    private var observerStartTask: Task<Void, Never>?

    public init(apiManager: any APIManagerProtocol,
                userManager: any UserManagerProtocol,
                authManager: any AuthManagerProtocol,
                mainKeyProvider: any MainKeyProvider,
                logger: Logger,
                paymentsV2: PaymentsV2 = PaymentsV2(),
                inMemoryTokenStorage: InMemoryTokenStorage = InMemoryTokenStorage(),
                transactionsObserver: any TransactionsObserverProviding = TransactionsObserver.shared) {
        self.transactionsObserver = transactionsObserver
        self.apiManager = apiManager
        self.userManager = userManager
        self.authManager = authManager
        self.mainKeyProvider = mainKeyProvider
        self.logger = logger
        self.paymentsV2 = paymentsV2
        self.inMemoryTokenStorage = inMemoryTokenStorage
        observeActiveUser()
    }

    isolated deinit {
        userObservation?.cancel()
        observerStartTask?.cancel()
        paymentFlow?.cancel()
    }
}

// MARK: - Public API

public extension PaymentsManager {
    /// Presents the plans UI. Returns `true` when a transaction completes,
    /// `false` on user cancellation or an SDK-reported payment failure.
    /// Cancelling the calling task tears down the observation.
//    func manageSubscription(isUpgrading: Bool) async throws -> Bool {
//        guard !Bundle.main.isBetaBuild else { return false }
//
//        // Actor reentrancy guard: the `for await` below is a suspension point,
//        // so a second call (double-tap) could interleave on the main actor.
//        guard !isPresentingPayments else { return false }
//        isPresentingPayments = true
//        defer { isPresentingPayments = false }
//
//        guard let userId = userManager.activeUserId else {
//            throw PassError.payments(.couldNotCreatePaymentStack)
//        }
//        let apiService = try apiManager.getApiService(userId: userId)
//
//        try paymentsV2.showAvailablePlans(presentationMode: .modal,
//                                          hideCurrentPlan: isUpgrading,
//                                          apiService: apiService)
//
//        for await progress in paymentsV2.transactionProgress.dropFirst().values {
//            switch progress {
//            case .transactionCompleted:
//                paymentsV2.dismissPayments()
//                return true
//
//            case .mismatchTransactionIDs,
//                 .transactionCancelledByUser,
//                 .transactionProcessError,
//                 .unableToGetUserTransactionUUID,
//                 .unknownError:
//                return false
//
//            default:
//                logger.debug("Unhandled transaction progress: \(progress)")
//            }
//        }
//        return false // publisher finished without a terminal event
//    }

    func manageSubscription(isUpgrading: Bool) async throws -> Bool {
        guard !Bundle.main.isBetaBuild else { return false }

        // A previous flow can dangle: interactive sheet dismissal emits no
        // terminal event from the SDK. Supersede it deterministically —
        // cancel AND await its unwind, so we never race its teardown.
        if let previous = paymentFlow {
            previous.cancel()
            _ = try? await previous.value
            paymentFlow = nil
        }

        guard let userData = userManager.currentActiveUser.value else {
            throw PassError.payments(.couldNotCreatePaymentStack)
        }
        let apiService = try apiManager.getApiService(userId: userData.user.ID)

        let flow = Task { [paymentsV2, logger] in
            try paymentsV2.showAvailablePlans(presentationMode: .modal,
                                              hideCurrentPlan: isUpgrading,
                                              apiService: apiService)

            for await progress in paymentsV2.transactionProgress.dropFirst().values {
                switch progress {
                case .transactionCompleted:
                    paymentsV2.dismissPayments()
                    return true

                case .mismatchTransactionIDs,
                     .transactionCancelledByUser,
                     .transactionProcessError,
                     .unableToGetUserTransactionUUID,
                     .unknownError:
                    return false

                default:
                    logger.debug("Unhandled transaction progress: \(progress)")
                }
            }
            return false
        }
        paymentFlow = flow
        defer { if paymentFlow == flow { paymentFlow = nil } }

        // Re-attach the unstructured flow to the caller's task tree:
        // cancelling the caller (VM) still tears the flow down.
        let result = try await withTaskCancellationHandler {
            try await flow.value
        } onCancel: {
            flow.cancel()
        }

        // A cancelled/superseded flow returns `false` from the loop ending —
        // don't report that as a real "no purchase" outcome.
        try Task.checkCancellation()
        return result
    }

    func restorePurchases() async throws {
        guard !Bundle.main.isBetaBuild else { return }
        let userID = try await userManager.getActiveUserId()
        let apiService = try apiManager.getApiService(userId: userID)
        _ = try await paymentsV2.restorePurchases(apiService: apiService)
    }
}

// MARK: - Active user → transactions observer

private extension PaymentsManager {
    func observeActiveUser() {
        // `[weak self]` re-bound per iteration: the loop doesn't pin self alive,
        // so `deinit` can run and cancel the task.
        userObservation = Task { [weak self, userManager] in
            for await userData in userManager.currentActiveUser.values {
                guard let self else { return }
                activeUserDidChange(userData)
            }
        }
    }

    func activeUserDidChange(_ userData: UserData?) {
        // Cancel unconditionally: an in-flight start for the *previous* user
        // must not outlive a logout or a user switch.
        observerStartTask?.cancel()

        guard let userData else {
            transactionsObserver.stop()
            return
        }

        let userId = userData.user.ID
        observerStartTask = Task { [apiManager, transactionsObserver, logger] in
            do {
                let apiService = try apiManager.getApiService(userId: userId)
                let configuration =
                    TransactionsObserverConfiguration(remoteManager: RemoteManager(apiService: apiService))
                transactionsObserver.setConfiguration(configuration)
                try await transactionsObserver.start()
            } catch is CancellationError {
                // Superseded by a newer active-user change; not an error.
            } catch {
                logger.error(error)
            }
        }
    }
}

// MARK: - StoreKitManagerDelegate

extension PaymentsManager: StoreKitManagerDelegate {
    public nonisolated var tokenStorage: (any PaymentTokenStorage)? {
        inMemoryTokenStorage
    }

    public nonisolated var isUnlocked: Bool {
        mainKeyProvider.mainKey?.isEmpty == false
    }

    public nonisolated var isSignedIn: Bool {
        guard let activeUserId = userManager.activeUserId else { return false }
        return authManager.isAuthenticated(userId: activeUserId)
    }

    public nonisolated var activeUsername: String? {
        userManager.currentActiveUser.value?.user.name
    }

    public nonisolated var userId: String? {
        userManager.currentActiveUser.value?.user.ID
    }
}

extension PaymentsManager: CurrentSubscriptionChangeDelegate {
    public nonisolated func onCurrentSubscriptionChange(old: ProtonCorePayments.Subscription?,
                                                        new: ProtonCorePayments.Subscription?) {
        // Nothing to do for now.
    }
}
