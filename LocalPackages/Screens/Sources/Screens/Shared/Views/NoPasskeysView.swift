//
// NoPasskeysView.swift
// Proton Pass - Created on 04/06/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import ProtonCoreUIFoundations
import SwiftUI

public struct NoPasskeysView: View {
    @Environment(\.openURL) private var openURL
    private let onCancel: () -> Void

    public init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                PassColor.backgroundNorm
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    Text("No logins with Passkeys found.", bundle: .module)
                        .font(.headline)
                        .foregroundStyle(PassColor.textNorm)
                    Button(action: {
                        if let url = URL(string: "https://proton.me/support/pass-autofill-fields-ios18") {
                            openURL(url)
                        }
                    }, label: {
                        Label("How to autofill fields with a Password",
                              systemImage: "questionmark.circle")
                            .foregroundStyle(PassColor.textWeak)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .overlay(Capsule()
                                .stroke(ColorProvider.InteractionWeak, lineWidth: 1))
                    })
                    .padding(.top)
                    .padding(.bottom, 44)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onCancel) {
                        Text("Cancel", bundle: .module)
                            .foregroundStyle(PassColor.interactionNormMajor2)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text("AutoFill Passkey", bundle: .module)
                        .fontWeight(.bold)
                        .foregroundStyle(PassColor.textNorm)
                }
            }
        }
    }
}
