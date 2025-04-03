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

import Entities
import Factory
import LocalAuthentication
import Screens
import SwiftUI

struct OnboardSection: View {
    @StateObject private var viewModel = OnboardSectionViewModel()
    @Binding var sheet: QaModal?
    @Binding var fullScreen: QaModal?

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
                if UIDevice.current.isIpad {
                    sheet = .onboarding
                } else {
                    fullScreen = .onboarding
                }
            }, label: {
                Text(verbatim: "Onboard")
            })

            Button(action: {
                if UIDevice.current.isIpad {
                    sheet = .onboardingV2(viewModel, viewModel)
                } else {
                    fullScreen = .onboardingV2(viewModel, viewModel)
                }
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

    init() {
        Task { [weak self] in
            guard let self else { return }
            onboarded = getAppPreferences().onboarded
        }
    }
}

extension OnboardSectionViewModel: OnboardingV2Datasource {
    func getAvailablePlans() async throws -> [PlanUiModel] {
        [
            .init(recurrence: .yearly, price: 85.0, currency: "CHF"),
            .init(recurrence: .monthly, price: 11, currency: "CHF")
        ]
    }

    func getBiometryType() async throws -> LABiometryType? {
        try checkBiometryType(policy: policy)
    }

    func isAutoFillEnabled() async -> Bool {
        await credentialManager.isAutoFillEnabled
    }

    func getFirstLoginSuggestion() async -> OnboardFirstLoginSuggestion {
        .suggestedShare(shareId: "")
    }
}

extension OnboardSectionViewModel: OnboardingV2Delegate {
    func purchase(_ plan: PlanUiModel) async throws {
        print(#function)
    }

    func enableBiometric() async throws {
        print(#function)
    }

    func enableAutoFill() async -> Bool {
        await enableAutoFillUseCase()
    }

    func createFirstLogin(payload: OnboardFirstLoginPayload) async throws {
        print(#function)
    }

    @MainActor
    func showLoadingIndicator() {
        router.display(element: .globalLoading(shouldShow: true))
    }

    @MainActor
    func hideLoadingIndicator() {
        router.display(element: .globalLoading(shouldShow: false))
    }

    @MainActor
    func handle(_ error: any Error) {
        router.display(element: .displayErrorBanner(error))
    }
}
