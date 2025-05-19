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

import FactoryKit
import Screens
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
                viewModel.present(view: OnboardingV2View(handler: viewModel.handler))
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

    @LazyInjected(\SharedUseCasesContainer.getAppPreferences)
    private var getAppPreferences

    @LazyInjected(\SharedUseCasesContainer.updateAppPreferences)
    private var updateAppPreferences

    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var router

    @LazyInjected(\ServiceContainer.onboardingV2Handler)
    var handler

    init() {
        onboarded = getAppPreferences().onboarded
    }

    func present(view: some View) {
        if UIDevice.current.isIpad {
            router.navigate(to: .sheet(view))
        } else {
            router.navigate(to: .fullScreen(view))
        }
    }
}
