//
// PinAuthenticationView.swift
// Proton Pass - Created on 22/06/2023.
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

import Core
import Factory
import SwiftUI
import UIComponents

struct PinAuthenticationView: View {
    @ObservedObject private var viewModel: LocalAuthenticationViewModel
    @FocusState private var isFocused
    @State private var pinCode = ""
    private let preferences = resolve(\SharedToolingContainer.preferences)

    init(viewModel: LocalAuthenticationViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .center) {
            Image(uiImage: PassIcon.passIcon)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 160)

            Text("Enter your PIN code")
                .foregroundColor(PassColor.textNorm.toColor)
                .font(.title.bold())

            Spacer()

            SecureField("", text: $pinCode)
                .labelsHidden()
                .foregroundColor(PassColor.textNorm.toColor)
                .font(.title.bold())
                .focused($isFocused)
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)

            Spacer()

            DisablableCapsuleTextButton(title: "Unlock",
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textInvert,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMajor1
                                            .withAlphaComponent(0.3),
                                        disabled: pinCode.count < Constants.PINCode.minLength,
                                        height: 60,
                                        action: { viewModel.checkPinCode(pinCode) })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .accentColor(PassColor.interactionNorm.toColor)
        .tint(PassColor.interactionNorm.toColor)
        .onAppear {
            isFocused = true
        }
    }
}
