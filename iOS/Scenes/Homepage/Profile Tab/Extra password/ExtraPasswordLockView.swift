//
// ExtraPasswordLockView.swift
// Proton Pass - Created on 06/06/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import Macro
import SwiftUI

struct ExtraPasswordLockView: View {
    @StateObject private var viewModel = ExtraPasswordLockViewModel()
    @FocusState private var focused
    let email: String
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .center) {
            Spacer()

            if let logo = UIImage(named: "LaunchScreenPassLogo") {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 88)
                    .padding(.bottom, 32)
            }

            Text("Enter your extra password")
                .font(.title.bold())
                .foregroundStyle(PassColor.textNorm.toColor)
                .multilineTextAlignment(.center)

            Text(email)
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(PassColor.textWeak.toColor)

            SecureField("Extra password", text: $viewModel.extraPassword)
                .font(.title2)
                .padding(.vertical, 32)
                .focused($focused)
                .multilineTextAlignment(.center)

            Spacer()

            DisablableCapsuleTextButton(title: #localized("Unlock"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canProceed,
                                        height: 60,
                                        action: { viewModel.unlock() })
        }
        .tint(PassColor.interactionNormMajor1.toColor)
        .padding()
        .background(PassColor.backgroundNorm.toColor)
        .onAppear { focused = true }
        .alert("Error occured",
               isPresented: errorBinding,
               actions: { Button(role: .cancel, label: { Text("Cancel") }) },
               message: { Text(viewModel.error?.localizedDescription ?? "") })
    }
}

private extension ExtraPasswordLockView {
    var errorBinding: Binding<Bool> {
        .init(get: { viewModel.error != nil },
              set: { _ in })
    }
}
