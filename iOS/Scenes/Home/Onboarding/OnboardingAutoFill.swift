//
// OnboardingAutoFill.swift
// Proton Pass - Created on 06/12/2022.
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

struct OnboardingAutoFill: View {
    let onProceed: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack {
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

            VStack(spacing: 0) {
                VStack {
                    Text("Turn on AutoFill")
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.vertical, 24)

                    // swiftlint:disable:next line_length
                    Text("AutoFill allows you to automatically enter your passwords in Safari and other apps, in a really fast and easy way.")
                        .foregroundColor(.textWeak)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    ColoredRoundedButton(title: "Turn on", action: onProceed)
                        .padding(.vertical, 26)

                    Button(action: onCancel) {
                        Text("Not now")
                            .foregroundColor(.interactionNorm)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(
            Image(uiImage: PassIcon.topLeftGradient)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }

    private func stepImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 36, height: 36)
    }
}

/*
struct OnboardingAutoFill_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingAutoFill(onProceed: {}, onCancel: {})
        OnboardingAutoFill(onProceed: {}, onCancel: {})
            .environment(\.colorScheme, .dark)
    }
}
*/
