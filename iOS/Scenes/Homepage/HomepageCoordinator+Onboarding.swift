//
// HomepageCoordinator+Onboarding.swift
// Proton Pass - Created on 16/04/2025.
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
import LocalAuthentication
import ProtonCorePaymentsUIV2
import ProtonCorePaymentsV2
import Screens
import StoreKit

extension HomepageCoordinator: OnboardingV2Datasource {
    func getAvailablePlans() async throws -> [ComposedPlan] {
        guard let manager = try await getPlansManager() else {
            return []
        }
        return try await manager.getAvailablePlans()
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

extension HomepageCoordinator: OnboardingV2Delegate {
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

    func enableBiometric() async throws {}

    func enableAutoFill() async -> Bool {
        await enableAutoFillUseCase()
    }

    func createFirstLogin(payload: OnboardFirstLoginPayload) async throws {}
}

private extension HomepageCoordinator {
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
