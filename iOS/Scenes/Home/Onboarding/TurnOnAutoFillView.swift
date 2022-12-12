//
// TurnOnAutoFillView.swift
// Proton Pass - Created on 09/12/2022.
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

import Client
import SwiftUI
import UIComponents

struct TurnOnAutoFillView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TurnOnAutoFillViewModel

    init(credentialManager: CredentialManagerProtocol) {
        _viewModel = .init(wrappedValue: .init(credentialManager: credentialManager))
    }

    var body: some View {
        VStack {
            if viewModel.enabled {
                OnboardingAutoFillEnabledView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                OnboardingAutoFillView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            VStack(spacing: 0) {
                VStack {
                    Spacer()

                    Text(viewModel.enabled ?
                         OnboardingViewState.autoFillEnabled.title :
                            OnboardingViewState.autoFill.title)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.vertical, 24)

                    Spacer()

                    Text(viewModel.enabled ?
                         OnboardingViewState.autoFillEnabled.description :
                            OnboardingViewState.autoFill.description)
                    .foregroundColor(.textWeak)
                    .multilineTextAlignment(.center)

                    Spacer()
                }

                Spacer()

                VStack {
                    ColoredRoundedButton(title: viewModel.enabled ? "Close" : "Go to Settings") {
                        if viewModel.enabled {
                            dismiss()
                        } else {
                            UIApplication.shared.openSettings()
                        }
                    }
                    .frame(height: 48)
                    .padding(.vertical, 26)

                    if !viewModel.enabled {
                        Button(action: dismiss.callAsFunction) {
                            Text("Not now")
                                .foregroundColor(.interactionNorm)
                                .transaction { transaction in
                                    transaction.animation = nil
                                }
                        }
                    }

                    Spacer()
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            LinearGradient(colors: [.brandNorm.opacity(0.2), .clear],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        )
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}
