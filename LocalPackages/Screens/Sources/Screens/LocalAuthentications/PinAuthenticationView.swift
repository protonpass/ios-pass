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

            Text("Enter your PIN code", bundle: .module)
                .foregroundStyle(PassColor.textNorm)
                .font(.title.bold())

            Spacer()

            SecureField(#localized("PIN code", bundle: .module), text: $pinCode)
                .labelsHidden()
                .foregroundStyle(PassColor.textNorm)
                .font(.title.bold())
                .focused($isFocused)
                .multilineTextAlignment(.center)
                .keyboardType(UIDevice.current.isIpad ? .default : .numberPad)

            Spacer()

            if viewModel.completionFailed {
                Text("Error occurred", bundle: .module)
                    .foregroundStyle(PassColor.signalDanger)
                    .multilineTextAlignment(.center)
            }

            switch viewModel.state {
            case .noAttempts:
                EmptyView()

            case let .remainingAttempts(count):
                if viewModel.completionFailed {
                    Text("\(count) remaining attempt(s)", bundle: .module)
                        .foregroundStyle(PassColor.signalDanger)
                } else {
                    Text("Incorrect PIN code.", bundle: .module)
                        .foregroundStyle(PassColor.signalDanger) +
                        Text(verbatim: " ") +
                        Text("\(count) remaining attempt(s)", bundle: .module)
                        .foregroundStyle(PassColor.signalDanger)
                }

            case .lastAttempt:
                Text("This is your last attempt. You will be logged out after failing to authenticate again.",
                     bundle: .module)
                    .foregroundStyle(PassColor.signalDanger)
                    .multilineTextAlignment(.center)

            case .exhausted:
                EmptyView()
            }

            Spacer()

            DisablableCapsuleTextButton(title: #localized("Unlock", bundle: .module),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textInvert,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMajor1.opacity(0.3),
                                        disabled: pinCode.count < Constants.PINCode.minLength
                                            || viewModel.isCheckingPinCode,
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
        .animation(.default, value: viewModel.completionFailed)
        .task {
            guard await (try? Task.sleep(for: viewModel.delayedTime)) != nil else { return }
            viewModel.onAuth()
            isFocused = true
        }
    }
}
