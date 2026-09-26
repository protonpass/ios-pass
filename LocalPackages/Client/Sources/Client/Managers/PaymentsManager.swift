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

import Combine
import Core
import Entities
import Foundation
@preconcurrency import ProtonCoreDoh
import ProtonCoreFeatureFlags
import ProtonCoreLogin
@preconcurrency import ProtonCorePayments
import ProtonCorePaymentsUIV2
import ProtonCorePaymentsV2

public final class PaymentsManager: Sendable {
    public typealias PaymentsResult = Result<Bool, any Error>

    private let apiManager: any APIManagerProtocol
    private let userManager: any UserManagerProtocol
    private let authManager: any AuthManagerProtocol
    private let mainKeyProvider: any MainKeyProvider
    private let logger: Logger
    private nonisolated let inMemoryTokenStorage: InMemoryTokenStorage
    private let paymentsV2: PaymentsV2
    private let transactionsObserver: any TransactionsObserverProviding
    private let storage: UserDefaults

    private nonisolated(unsafe) var cancellables: Set<AnyCancellable> = []
    private nonisolated(unsafe) var transactionTask: Task<Void, Never>?

    public init(apiManager: any APIManagerProtocol,
                userManager: any UserManagerProtocol,
                authManager: any AuthManagerProtocol,
                mainKeyProvider: any MainKeyProvider,
                logger: Logger,
                storage: UserDefaults,
                transactionsObserver: any TransactionsObserverProviding,
                paymentsV2: PaymentsV2 = PaymentsV2(),
                inMemoryTokenStorage: InMemoryTokenStorage = InMemoryTokenStorage()) {
        self.transactionsObserver = transactionsObserver
        self.apiManager = apiManager
        self.userManager = userManager
        self.authManager = authManager
        self.mainKeyProvider = mainKeyProvider
        self.logger = logger
        self.paymentsV2 = paymentsV2
        self.inMemoryTokenStorage = inMemoryTokenStorage
        self.storage = storage
        setup()
    }

    @MainActor
    public func manageSubscription(isUpgrading: Bool,
                                   completion: @escaping (Result<Bool, any Error>) -> Void) {
        guard !Bundle.main.isBetaBuild else {
            return
        }
        do {
            try createPaymentsV2UI(hideCurrentPlan: isUpgrading, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    public func restorePurchases() async throws {
        guard !Bundle.main.isBetaBuild else { return }
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
    public var tokenStorage: (any PaymentTokenStorage)? {
        inMemoryTokenStorage
    }

    public var isUnlocked: Bool {
        mainKeyProvider.mainKey?.isEmpty == false
    }

    public var isSignedIn: Bool {
        guard let activeUserId = userManager.activeUserId else {
            return false
        }
        return authManager.isAuthenticated(userId: activeUserId)
    }

    public var activeUsername: String? {
        userManager.currentActiveUser.value?.user.name
    }

    public var userId: String? {
        userManager.currentActiveUser.value?.user.ID
    }
}

extension PaymentsManager: CurrentSubscriptionChangeDelegate {
    public func onCurrentSubscriptionChange(old: ProtonCorePayments.Subscription?,
                                            new: ProtonCorePayments.Subscription?) {
        // Nothing to do here for now, I guess?
    }
}
