//
// OnboardingView.swift
// Proton Pass - Created on 08/12/2022.
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

import SwiftUI
import UIComponents

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack {
            VStack {
                switch viewModel.state {
                case .autoFill:
                    OnboardingAutoFillView()
                case .autoFillEnabled:
                    OnboardingAutoFillEnabledView()
                case .biometricAuthentication:
                    OnboardingBiometricAuthenticationView()
                case .biometricAuthenticationEnabled:
                    Text("biometricAuthenticationEnabled")
                case .aliases:
                    Text("aliases")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.default, value: viewModel.state)

            VStack(spacing: 0) {
                VStack {
                    Text(viewModel.state.title)
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.vertical, 24)

                    Text(viewModel.state.description)
                        .foregroundColor(.textWeak)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    ColoredRoundedButton(title: viewModel.state.primaryButtonTitle,
                                         action: viewModel.primaryAction)
                        .padding(.vertical, 26)

                    if let secondaryButtonTitle = viewModel.state.secondaryButtonTitle {
                        Button(action: viewModel.secondaryAction) {
                            Text(secondaryButtonTitle)
                                .foregroundColor(.interactionNorm)
                        }
                        .animation(.default, value: viewModel.state.secondaryButtonTitle)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
            }
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
        .onReceiveBoolean(viewModel.$finished, perform: dismiss.callAsFunction)
    }
}

private struct OnboardingAutoFillView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 16) {
                VStack(spacing: 24) {
                    stepImage(PassIcon.onboardAutoFillStep1)
                    stepImage(PassIcon.onboardAutoFillStep2)
                    stepImage(PassIcon.onboardAutoFillStep3)
                    stepImage(PassIcon.onboardAutoFillStep4)
                    stepImage(PassIcon.onboardAutoFillStep5)
                }
                .background(
                    Image(uiImage: PassIcon.onboardAutoFillGradient)
                        .resizable()
                        .frame(width: 2)
                        .padding(.vertical, 36))

                VStack(alignment: .leading, spacing: 24) {
                    Text("Open **Settings** app")
                        .frame(height: 36)
                    Text("Tap **Passwords**")
                        .frame(height: 36)
                    Text("Tap **Password Options**")
                        .frame(height: 36)
                    Text("Turn on **Autofill Passwords**")
                        .frame(height: 36)
                    Text("Select **Proton Pass**")
                        .frame(height: 36)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stepImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 36, height: 36)
    }
}

private struct OnboardingAutoFillEnabledView: View {
    var body: some View {
        VStack {
            Spacer()
            Color.clear
            Spacer()
            Image(uiImage: PassIcon.onboardAutoFillEnabled)
                .resizable()
                .scaledToFit()
            Spacer()
        }
    }
}

private struct OnboardingBiometricAuthenticationView: View {
    var body: some View {
        Image(uiImage: PassIcon.onboardBiometricAuthentication)
            .resizable()
            .scaledToFill()
            .padding(.top, 80)
    }
}
