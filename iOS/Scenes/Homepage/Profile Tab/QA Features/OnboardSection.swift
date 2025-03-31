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
    @State private var isShowingFullScreen = false
    @State private var isShowingSheet = false
    @State private var isShowingFullScreenV2 = false
    @State private var isShowingSheetV2 = false

    var body: some View {
        Section(content: {
            Button(action: {
                if UIDevice.current.isIpad {
                    isShowingSheet.toggle()
                } else {
                    isShowingFullScreen.toggle()
                }
            }, label: {
                Text(verbatim: "Onboard")
            })

            Button(action: {
                if UIDevice.current.isIpad {
                    isShowingSheetV2.toggle()
                } else {
                    isShowingFullScreenV2.toggle()
                }
            }, label: {
                Text(verbatim: "Onboard V2")
            })
        }, header: {
            Text(verbatim: "👋")
        })
        .fullScreenCover(isPresented: $isShowingFullScreen) { onboardingView }
        .sheet(isPresented: $isShowingSheet) { onboardingView }
        .fullScreenCover(isPresented: $isShowingFullScreenV2) { onboardingV2 }
        .sheet(isPresented: $isShowingSheetV2) { onboardingV2 }
    }
}

private extension OnboardSection {
    var onboardingView: some View {
        OnboardingView(onWatchTutorial: {})
    }

    var onboardingV2: some View {
        OnboardingV2View(isFreeUser: true,
                         datasource: viewModel,
                         delegate: viewModel)
    }
}

@MainActor
private final class OnboardSectionViewModel: ObservableObject {
    @LazyInjected(\SharedServiceContainer.credentialManager)
    private var credentialManager

    @LazyInjected(\UseCasesContainer.enableAutoFill)
    private var enableAutoFillUseCase

    @LazyInjected(\SharedUseCasesContainer.checkBiometryType)
    private var checkBiometryType

    @LazyInjected(\SharedToolingContainer.localAuthenticationEnablingPolicy)
    private var policy

    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var router
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

    @MainActor
    func handle(_ error: any Error) {
        router.display(element: .displayErrorBanner(error))
    }
}
