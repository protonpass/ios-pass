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

import DesignSystem
import Factory
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = OnboardingViewModel()
    let onWatchTutorial: () -> Void

    var body: some View {
        VStack {
            VStack {
                switch viewModel.state {
                case .autoFill:
                    VStack {
                        Spacer()
                        if #unavailable(iOS 18) {
                            OnboardingAutoFillView()
                        }
                    }
                case .autoFillEnabled:
                    OnboardingAutoFillEnabledView()
                case .biometricAuthenticationFaceID, .biometricAuthenticationTouchID:
                    OnboardingBiometricAuthenticationView(enabled: false)
                case .faceIDEnabled, .touchIDEnabled:
                    OnboardingBiometricAuthenticationView(enabled: true)
                case .aliases:
                    OnboardingAliasesView()
                }
            }
            .animation(.default, value: viewModel.state)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Text(viewModel.state.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PassColor.textNorm.toColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(viewModel.state.description)
                        .foregroundStyle(PassColor.textWeak.toColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                Spacer()

                VStack {
                    CapsuleTextButton(title: viewModel.state.primaryButtonTitle,
                                      titleColor: PassColor.textInvert,
                                      backgroundColor: PassColor.interactionNormMajor1,
                                      height: 60,
                                      action: { viewModel.primaryAction() })
                        .padding(.vertical, 26)

                    if let secondaryButtonTitle = viewModel.state.secondaryButtonTitle {
                        Button { viewModel.secondaryAction() } label: {
                            Text(secondaryButtonTitle)
                                .foregroundStyle(PassColor.interactionNormMajor2.toColor)
                                .animationsDisabled()
                        }
                        .animation(.default, value: viewModel.state.secondaryButtonTitle)
                    } else if viewModel.state == .aliases {
                        Button(action: onWatchTutorial) {
                            Label(title: { Text("Watch a short video on how to use Proton Pass") },
                                  icon: { Image(uiImage: PassIcon.youtube) })
                                .foregroundStyle(PassColor.interactionNorm.toColor)
                                .labelStyle(.belowIcon)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(verbatim: "Dummy text that takes place")
                            .opacity(0)
                    }

                    Spacer()
                }
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .background(PassColor.backgroundNorm.toColor)
        .edgesIgnoringSafeArea(.all)
        .onReceiveBoolean(viewModel.$finished, perform: dismiss.callAsFunction)
    }
}

struct OnboardingAutoFillView: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 24) {
                stepImage(PassIcon.onboardAutoFillStep1)
                stepImage(PassIcon.onboardAutoFillStep2)
                stepImage(PassIcon.onboardAutoFillStep3)
                stepImage(PassIcon.onboardAutoFillStep4)
                stepImage(PassIcon.onboardAutoFillStep5)
            }
            .background(Image(uiImage: PassIcon.onboardAutoFillGradient)
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
            .foregroundStyle(PassColor.textNorm.toColor)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 36, height: 36)
    }
}

struct OnboardingAutoFillEnabledView: View {
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
    let enabled: Bool
    var body: some View {
        ZStack {
            Image(uiImage: PassIcon.onboardAuthenticationBackground)
                .resizable()
                .scaledToFit()
            Image(uiImage: enabled ? PassIcon.onboardAuthenticationEnabled : PassIcon.onboardAuthentication)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 180)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OnboardingAliasesView: View {
    var body: some View {
        GeometryReader { proxy in
            VStack {
                Spacer()
                Image(uiImage: PassIcon.onboardAliases)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: min(proxy.size.width, proxy.size.height))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
