//
// AutoFillSettingsView.swift
// Proton Pass - Created on 22/12/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct AutoFillSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    let onGoBack: () -> Void

    var body: some View {
        Group {
            if viewModel.autoFillEnabled {
                AutoFillEnabledView(viewModel: viewModel)
            } else {
                AutoFillDisabledView()
                    .padding()
                    .background(OnboardingGradientBackground())
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .animation(.default, value: viewModel.autoFillEnabled)
        .tint(.interactionNorm)
        .navigationBarBackButtonHidden()
        .toolbar { toolbarContent }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: onGoBack) {
                Image(uiImage: IconProvider.chevronLeft)
                    .foregroundColor(.primary)
            }
        }

        ToolbarItem(placement: .principal) {
            Text("AutoFill")
        }
    }
}

private struct AutoFillDisabledView: View {
    var body: some View {
        VStack {
            Spacer()
            OnboardingAutoFillView()
            ColoredRoundedButton(title: "Go to Settings",
                                 action: UIApplication.shared.openPasswordSettings)
            .padding(.top)
            Spacer()
        }
    }
}

private struct AutoFillEnabledView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section(content: {
                Toggle(isOn: $viewModel.quickTypeBar) {
                    Text("QuickType bar suggestions")
                }
                .tint(.interactionNorm)
            }, footer: {
                // swiftlint:disable:next line_length
                Text("QuickType bar helps quickly select a matched credential without opening the AutoFill extension.")
            })
        }
    }
}
