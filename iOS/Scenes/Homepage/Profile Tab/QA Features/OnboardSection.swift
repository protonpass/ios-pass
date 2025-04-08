//
// OnboardSection.swift
// Proton Pass - Created on 15/04/2023.
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
import Entities
import Factory
import LocalAuthentication
import ProtonCorePaymentsUIV2
import ProtonCorePaymentsV2
import Screens
import StoreKit
import SwiftUI

struct OnboardSection: View {
    @StateObject private var viewModel = OnboardSectionViewModel()

    var body: some View {
        Section(content: {
            VStack(alignment: .leading) {
                Toggle(isOn: $viewModel.onboarded) {
                    Text(verbatim: "Onboarded")
                }
                Text(verbatim: "Automatically onboard after logging in with the first account")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                viewModel.present(view: OnboardingView(onWatchTutorial: {}))
            }, label: {
                Text(verbatim: "Onboard")
            })

            Button(action: {
                viewModel.present(view: OnboardingV2View(datasource: viewModel,
                                                         delegate: viewModel))
            }, label: {
                Text(verbatim: "Onboard V2")
            })
        }, header: {
            Text(verbatim: "👋")
        })
    }
}

@MainActor
private final class OnboardSectionViewModel: ObservableObject {
    @Published var onboarded = false {
        didSet {
            Task { [weak self] in
                guard let self else { return }
                try? await updateAppPreferences(\.onboarded, value: onboarded)
            }
        }
    }

    @LazyInjected(\SharedServiceContainer.credentialManager)
    private var credentialManager

    @LazyInjected(\UseCasesContainer.enableAutoFill)
    private var enableAutoFillUseCase

    @LazyInjected(\SharedUseCasesContainer.checkBiometryType)
    private var checkBiometryType

    @LazyInjected(\SharedUseCasesContainer.getAppPreferences)
    private var getAppPreferences

    @LazyInjected(\SharedUseCasesContainer.updateAppPreferences)
    private var updateAppPreferences

    @LazyInjected(\SharedToolingContainer.localAuthenticationEnablingPolicy)
    private var policy

    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var router

    @LazyInjected(\SharedToolingContainer.doh)
    private var doh

    @LazyInjected(\SharedDataContainer.credentialProvider)
    private var credentialProvider

    @LazyInjected(\SharedServiceContainer.userManager)
    private var userManager

    @LazyInjected(\SharedToolingContainer.appVersion)
    private var appVersion

    private var plansManager: ProtonPlansManager?

    init() {
        Task { [weak self] in
            guard let self else { return }
            onboarded = getAppPreferences().onboarded
        }
    }

    func present(view: some View) {
        if UIDevice.current.isIpad {
            router.navigate(to: .sheet(view))
        } else {
            router.navigate(to: .fullScreen(view))
        }
    }
}

private extension OnboardSectionViewModel {
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

extension OnboardSectionViewModel: OnboardingV2Datasource {
    func getAvailablePlans() async throws -> [ComposedPlan] {
        guard let manager = try await getPlansManager() else {
            return []
        }
        return try await manager.getAvailablePlans()
    }

    func getBiometryType() async throws -> LABiometryType? {
        try checkBiometryType(policy: policy)
    }

    func isAutoFillEnabled() async -> Bool {
        await credentialManager.isAutoFillEnabled
    }

    func getFirstLoginSuggestion() async -> OnboardFirstLoginSuggestion {
        .none
    }
}

extension OnboardSectionViewModel: OnboardingV2Delegate {
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
        print(#function)
    }

    func enableAutoFill() async -> Bool {
        await enableAutoFillUseCase()
    }

    func createFirstLogin(payload: OnboardFirstLoginPayload) async throws {
        try await Task.sleep(seconds: 2)
        print(payload)
    }

    @MainActor
    func handle(_ error: any Error) {
        router.display(element: .displayErrorBanner(error))
    }
}
