//
// OnboardingAliases.swift
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

struct OnboardingAliases: View {
    let onAction: () -> Void

    var body: some View {
        VStack {
            VStack {
                Spacer()
                Image(uiImage: PassIcon.onboardAliases)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                VStack {
                    Text("Protect your true email address")
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.vertical, 24)

                    // swiftlint:disable:next line_length
                    Text("With email aliases, you can be anonymous online and protect your inbox against spams and phishing.")
                        .foregroundColor(.textWeak)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    ColoredRoundedButton(title: "Get started", action: onAction)
                        .padding(.vertical, 26)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}
