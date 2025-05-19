//
// OnboardingV2Handler.swift
// Proton Pass - Created on 17/04/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import FactoryKit
import LocalAuthentication
import Macro
import ProtonCorePaymentsUIV2
import ProtonCorePaymentsV2
import Screens
import StoreKit

@MainActor
final class OnboardingV2Handler {
    @LazyInjected(\SharedToolingContainer.preferencesManager)
    private var preferencesManager

    @LazyInjected(\SharedServiceContainer.credentialManager)
    private var credentialManager

    @LazyInjected(\SharedDataContainer.credentialProvider)
    private var credentialProvider

    @LazyInjected(\SharedServiceContainer.userManager)
    private var userManager

    @LazyInjected(\SharedRepositoryContainer.accessRepository)
    private var accessRepository

    @LazyInjected(\SharedUseCasesContainer.checkBiometryType)
    private var checkBiometryType

    @LazyInjected(\SharedToolingContainer.localAuthenticationEnablingPolicy)
    private var localAuthenticationEnablingPolicy

    @LazyInjected(\SharedToolingContainer.doh)
    private var doh

    @LazyInjected(\SharedToolingContainer.appVersion)
    private var appVersion

    @LazyInjected(\UseCasesContainer.enableAutoFill)
    private var enableAutoFillUseCase

    @LazyInjected(\SharedUseCasesContainer.authenticateBiometrically)
    private var authenticateBiometrically

    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var router

    @LazyInjected(\ SharedUseCasesContainer.addTelemetryEvent)
    private var addTelemetryEvent

    private var plansManager: ProtonPlansManager?
    private let logger: Logger

    nonisolated init(logManager: any LogManagerProtocol) {
        logger = .init(manager: logManager)
    }
}

extension OnboardingV2Handler: OnboardingV2Datasource {
    func getCurrentPlan() async throws -> Entities.Plan {
        try await accessRepository.getPlan(userId: nil)
    }

    func getPassPlans() async throws -> PassPlans? {
        guard !Bundle.main.isBetaBuild, let manager = try await getPlansManager() else {
            return nil
        }
        let plans = try await manager.getAvailablePlans()
        let plusId = "iospass_pass2023_12_usd_auto_renewing"
        let unlimitedId = "iospass_bundle2022_12_usd_auto_renewing"
        if let plusComposedPlan = plans.first(where: { $0.product.id == plusId }),
           let plusPlan = PlanUiModel(plan: plusComposedPlan),
           let unlimitedComposedPlan = plans.first(where: { $0.product.id == unlimitedId }),
           let unlimitedPlan = PlanUiModel(plan: unlimitedComposedPlan) {
            return .init(plus: plusPlan, unlimited: unlimitedPlan)
        } else {
            return nil
        }
    }

    func getBiometryType() async throws -> LABiometryType? {
        try checkBiometryType(policy: localAuthenticationEnablingPolicy)
    }

    func isAutoFillEnabled() async -> Bool {
        await credentialManager.isAutoFillEnabled
    }

    // periphery:ignore
    func getFirstLoginSuggestion() async -> OnboardFirstLoginSuggestion {
        .none
    }
}

extension OnboardingV2Handler: OnboardingV2Delegate {
    func purchase(_ plan: ComposedPlan) async throws {
        guard let manager = try await getPlansManager() else { return }

        guard let product = plan.product as? Product else {
            assertionFailure("Failed to parse product")
            return
        }
        let cycle = BillingCycle(rawValue: plan.instance.cycle) ?? .all
        _ = try await manager.purchase(product,
                                       planName: plan.plan.name ?? "",
                                       planCycle: cycle.rawValue)
    }

    func enableBiometric() async throws {
        let authenticated = try await authenticateBiometrically(policy: localAuthenticationEnablingPolicy,
                                                                reason: #localized("Please authenticate"))
        if authenticated {
            try await preferencesManager.updateSharedPreferences(\.localAuthenticationMethod,
                                                                 value: .biometric)
        }
    }

    func enableAutoFill() async -> Bool {
        await enableAutoFillUseCase()
    }

    func openTutorialVideo() {
        router.navigate(to: .urlPage(urlString: ProtonLink.youtubeTutorial))
    }

    // periphery:ignore
    func createFirstLogin(payload: OnboardFirstLoginPayload) async throws {}

    func markAsOnboarded() async {
        // Optionally update "onboarded" to not block users from using the app
        // in case errors happens
        try? await preferencesManager.updateAppPreferences(\.onboarded, value: true)
    }

    func add(event: TelemetryEventType) {
        addTelemetryEvent(with: event)
    }

    func handle(error: any Error) {
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}

private extension OnboardingV2Handler {
    func getPlansManager() async throws -> ProtonPlansManager? {
        if let plansManager {
            return plansManager
        }
        guard let doh = doh as? ProtonPassDoH else {
            assertionFailure("DoH should be ProtonPassDoH")
            return nil
        }

        let userId = try await userManager.getActiveUserId()
        guard let credentials = credentialProvider.getCredential(userId: userId) else {
            assertionFailure("No credentials for current user")
            return nil
        }

        let remoteManager = RemoteManager(sessionID: credentials.sessionID,
                                          authToken: credentials.accessToken,
                                          appVersion: appVersion)
        let manager = ProtonPlansManager(doh: doh,
                                         remoteManager: remoteManager)
        plansManager = manager
        return manager
    }
}
