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
import Combine
import Core
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreAccountRecovery
import ProtonCoreDataModel
import ProtonCoreFeatureFlags
import ProtonCoreLogin
import ProtonCorePasswordChange

@MainActor
protocol AccountViewModelDelegate: AnyObject {
    func accountViewModelWantsToGoBack()
    func accountViewModelWantsToShowAccountRecovery(_ completion: @escaping (AccountRecovery) -> Void)
}

@MainActor
final class AccountViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let accessRepository = resolve(\SharedRepositoryContainer.accessRepository)
    private let accountRepository = resolve(\SharedRepositoryContainer.accountRepository)
    private let featureFlagsRepository = resolve(\SharedRepositoryContainer.featureFlagsRepository)
    private let userManager = resolve(\SharedServiceContainer.userManager)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let paymentsManager = resolve(\ServiceContainer.paymentManager) // To remove after Dynaplans
    private let userSettingsRepository = resolve(\SharedRepositoryContainer.userSettingsRepository)
    private let preferencesManager = resolve(\SharedToolingContainer.preferencesManager)
    private let doDisableExtraPassword = resolve(\UseCasesContainer.disableExtraPassword)

    let isShownAsSheet: Bool
    @Published private(set) var shouldShowSecurityKeys = false
    @Published private(set) var plan: Plan?
    @Published private(set) var isLoading = false
    @Published private(set) var canManageSubscription = false
    @Published private(set) var passwordMode: UserSettings.Password.PasswordMode = .singlePassword
    @Published private(set) var extraPasswordEnabled = false
    @Published var extraPassword = ""
    private(set) var accountRecovery: AccountRecovery?

    private var cancellables = Set<AnyCancellable>()
    weak var delegate: (any AccountViewModelDelegate)?

    var username: String { userManager.currentActiveUser.value?.user.email ?? "" }

    var canRestorePurchases: Bool {
        !Bundle.main.isBetaBuild &&
            plan?.isBusinessUser == false &&
            featureFlagsRepository.isEnabled(CoreFeatureFlagType.paymentsV2)
    }

    var isSSOUser: Bool {
        (userManager.currentActiveUser.value?.user.isSSOAccount ?? false)
    }

    init(isShownAsSheet: Bool) {
        self.isShownAsSheet = isShownAsSheet
        setup()

        preferencesManager
            .userPreferencesUpdates
            .receive(on: DispatchQueue.main)
            .filter(\.extraPasswordEnabled)
            .sink { [weak self] enabled in
                guard let self else { return }
                extraPasswordEnabled = enabled
            }
            .store(in: &cancellables)

        userManager
            .currentActiveUser
            .receive(on: DispatchQueue.main)
            .compactMap(\.?.user.canManageSubscription)
            .sink { [weak self] canManageSubscription in
                guard let self else { return }
                // Temporarily hide "Manage subscription" option while waiting for dynamic plans
                let isB2B = plan?.isBusinessUser == true
                self.canManageSubscription = canManageSubscription && !isB2B
            }
            .store(in: &cancellables)
    }
}

extension AccountViewModel {
    func goBack() {
        delegate?.accountViewModelWantsToGoBack()
    }

    func manageSubscription() {
        paymentsManager.manageSubscription(isUpgrading: false) { [weak self] result in
            guard let self else { return }
            handlePaymentsResult(result: result)
        }
    }

    func upgradeSubscription() {
        paymentsManager.manageSubscription(isUpgrading: true) { [weak self] result in
            guard let self else { return }
            handlePaymentsResult(result: result)
        }
    }

    func restorePurchases() {
        Task { [weak self] in
            guard let self else { return }
            defer { isLoading = false }
            isLoading = true
            do {
                try await paymentsManager.restorePurchases()
                try await accessRepository.refreshAccess(userId: nil)
            } catch {
                handle(error: error)
            }
        }
    }

    var canChangePassword: Bool {
        featureFlagsRepository.isEnabled(CoreFeatureFlagType.changePassword, reloadValue: true)
            && !(userManager.currentActiveUser.value?.user.isSSOAccount ?? false)
    }

    var canChangeMailboxPassword: Bool {
        guard canChangePassword else { return false }
        return passwordMode == .loginAndMailboxPassword
    }

    func openChangeUserPassword() {
        let mode: PasswordChangeModule
            .PasswordChangeMode = passwordMode == .singlePassword ? .singlePassword : .loginPassword
        router.present(for: .changePassword(mode))
    }

    func openChangeMailboxPassword() {
        router.present(for: .changePassword(.mailboxPassword))
    }

    func openAccountSettings() {
        router.present(for: .accountSettings)
    }

    func showSecurityKeys() {
        router.present(for: .securityKeys)
    }

    func enableExtraPassword() {
        router.present(for: .enableExtraPassword)
    }

    func disableExtraPassword() {
        guard let username = userManager.currentActiveUser.value?.credential.userName else {
            let errorMessage = #localized("Missing username")
            router.display(element: .errorMessage(errorMessage))
            logger.error("Failed to disable extra password. Missing username")
            return
        }
        Task { [weak self] in
            guard let self else { return }
            defer { isLoading = false }
            isLoading = true
            do {
                let userId = try await userManager.getActiveUserId()
                let result = try await doDisableExtraPassword(userId: userId,
                                                              username: username,
                                                              password: extraPassword)
                extraPassword = ""
                switch result {
                case .successful:
                    let message = #localized("Extra password disabled")
                    router.display(element: .infosMessage(message))
                    try await preferencesManager.updateUserPreferences(\.extraPasswordEnabled, value: false)
                case .tooManyAttempts, .wrongPassword:
                    let errorMessage = #localized("Wrong extra password")
                    router.display(element: .errorMessage(errorMessage))
                }
            } catch {
                handle(error: error)
            }
        }
    }

    func signOut() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                router.action(.signOut(userId: userId))
            } catch {
                handle(error: error)
            }
        }
    }

    func deleteAccount() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                router.action(.deleteAccount(userId: userId))
            } catch {
                handle(error: error)
            }
        }
    }

    func openAccountRecovery() {
        delegate?.accountViewModelWantsToShowAccountRecovery { _ in
            self.refreshAccountRecovery()
        }
    }
}

private extension AccountViewModel {
    func setup() {
        plan = accessRepository.access.value?.access.plan
        extraPasswordEnabled = preferencesManager.userPreferences.unwrapped().extraPasswordEnabled
        canManageSubscription = userManager.currentActiveUser.value?.user.canManageSubscription ?? false
        refreshUserPlan()
        refreshAccountRecovery()
        refreshAccountPasswordMode()
        checkFidoActivation()
    }

    func refreshUserPlan() {
        Task { [weak self] in
            guard let self else { return }
            do {
                plan = try await accessRepository.refreshAccess(userId: nil).access.plan
            } catch {
                logger.error(error)
            }
        }
    }

    func refreshAccountRecovery() {
        guard featureFlagsRepository.isEnabled(CoreFeatureFlagType.accountRecovery, reloadValue: true) else {
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                accountRecovery = try await accountRepository.accountRecovery()
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func refreshAccountPasswordMode() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let userId = try await userManager.getActiveUserId()
                let settings = await userSettingsRepository.getSettings(for: userId)
                passwordMode = settings.password.mode
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func handlePaymentsResult(result: PaymentsManager.PaymentsResult) {
        switch result {
        case let .success(inAppPurchasePlan):
            if inAppPurchasePlan {
                refreshUserPlan()
            } else {
                logger
                    .debug("""
                    Payment is done but no plan is purchased.
                     Or purchase was cancelled.
                     Or completed, and sheet is being dismissed.
                    """)
            }
        case let .failure(error):
            logger.error(error)
        }
    }

    private func checkFidoActivation() {
        Task { @MainActor [weak self] in
            guard let self, let userId = try? await userManager.getActiveUserId() else { return }
            let settings = await userSettingsRepository.getSettings(for: userId)

            shouldShowSecurityKeys = settings.twoFactor.type == .fido2 && !isSSOUser
        }
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

private extension User {
    var canManageSubscription: Bool {
        role != 1
    }
}
