//
// OnboardingBiometricAuthentication.swift
// Proton Pass - Created on 07/12/2022.
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

struct OnboardingBiometricAuthentication: View {
    let onProceed: () -> Void
    let onCancel: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                Image(uiImage: PassIcon.onboardBiometricAuthentication)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width)
                    .padding(.top, 80)

                VStack {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VStack(spacing: 0) {
                        VStack {
                            Text("Protect what matters most")
                                .font(.title2)
                                .fontWeight(.medium)
                                .padding(.vertical, 24)

                            Text("Enable Face ID or Touch ID to shield your device from prying eyes.")
                                .foregroundColor(.textWeak)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        VStack {
                            ColoredRoundedButton(title: "Enable", action: onProceed)
                                .padding(.vertical, 26)

                            Button(action: onCancel) {
                                Text("No thanks")
                                    .foregroundColor(.interactionNorm)
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color(.systemBackground))
            .edgesIgnoringSafeArea(.all)
        }
    }
}
