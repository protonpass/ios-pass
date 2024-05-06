//
//
// AddCustomEmailView.swift
// Proton Pass - Created on 18/04/2024.
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
//

import DesignSystem
import Entities
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct AddCustomEmailView: View {
    @StateObject var viewModel: AddCustomEmailViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused
    @State private var showErrorAlert = false

    var body: some View {
        VStack {
            if viewModel.customEmail != nil {
                Text("We sent a verification code to \(viewModel.email). Enter it below:")
                    .font(.body)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                TextField("Code", text: $viewModel.code)
                    .focused($focused)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .tint(PassColor.interactionNorm.toColor)
                    .frame(height: 64)
            } else {
                TextField("Email address", text: $viewModel.email)
                    .focused($focused)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .tint(PassColor.interactionNorm.toColor)
                    .frame(height: 64)
            }

            DisablableCapsuleTextButton(title: #localized("Continue"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.interactionNormMajor1,
                                        disableBackgroundColor: PassColor.interactionNormMinor1,
                                        disabled: !viewModel.canContinue,
                                        height: 44,
                                        action: { viewModel.nextStep() })

            Spacer()
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.canContinue)
        .toolbar { toolbarContent }
        .background(PassColor.backgroundNorm.toColor)
        .onChange(of: viewModel.finishedVerification) { isVerificationFinished in
            guard isVerificationFinished else {
                return
            }
            dismiss()
        }
        .onReceive(viewModel.$verificationError) { error in
            showErrorAlert = error != nil
        }
        .alert("Error occured",
               isPresented: $showErrorAlert,
               actions: {
                   Button(action: dismiss.callAsFunction) {
                       Text("OK")
                   }
               },
               message: {
                   if let message = viewModel.verificationError?.localizedDescription {
                       Text(message)
                   }
               })
        .onAppear { focused = true }
        .navigationTitle(viewModel.customEmail != nil ? "Confirm your email" : "Custom email monitoring")
        .navigationStackEmbeded()
    }
}

private extension AddCustomEmailView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }
    }
}
