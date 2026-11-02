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
import DesignSystem
import Macro
import SwiftUI

struct PinAuthenticationView: View {
    @Bindable var viewModel: LocalAuthenticationViewModel
    @FocusState private var isFocused
    @State private var pinCode = ""

    var body: some View {
        VStack(alignment: .center) {
            Spacer()

            PassIcon.passIcon
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 160)

            Text("Enter your PIN code")
                .foregroundStyle(PassColor.textNorm)
                .font(.title.bold())

            Spacer()

            SecureField("PIN code", text: $pinCode)
                .labelsHidden()
                .foregroundStyle(PassColor.textNorm)
                .font(.title.bold())
                .focused($isFocused)
                .multilineTextAlignment(.center)
                .keyboardType(UIDevice.current.isIpad ? .default : .numberPad)

            Spacer()

            if let failureMessage = viewModel.failureMessage {
                Text(failureMessage)
                    .foregroundStyle(PassColor.signalDanger)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            DisablableCapsuleTextButton(title: #localized("Unlock"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textInvert,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMajor1.opacity(0.3),
                                        disabled: pinCode.count < Constants.PINCode.minLength,
                                        height: 60,
                                        action: {
                                            viewModel.checkPinCode(pinCode)
                                            isFocused = false
                                            pinCode = ""
                                        })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .if(viewModel.manuallyAvoidKeyboard) { view in
            view
                .keyboardAwarePadding()
        }
        .accentColor(PassColor.interactionNorm)
        .tint(PassColor.interactionNorm)
        .animation(.default, value: viewModel.state)
        .onAppear {
            let notifyAuthProcessAndFocus: () -> Void = {
                viewModel.onAuth()
                isFocused = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + viewModel.delayedTime) {
                notifyAuthProcessAndFocus()
            }
        }
    }
}
