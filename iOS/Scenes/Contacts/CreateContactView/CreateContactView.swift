//
//
// CreateContactView.swift
// Proton Pass - Created on 04/10/2024.
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

struct CreateContactView: View {
    @StateObject var viewModel: CreateContactViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding * 2) {
            TextField("Email address", text: $viewModel.email)
                .focused($focused)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .foregroundStyle(PassColor.textNorm.toColor)
                .tint(PassColor.interactionNorm.toColor)
                .frame(height: 64)

            TextField("Name for contact detail", text: $viewModel.name)
                .keyboardType(.asciiCapable)
                .autocorrectionDisabled()
                .foregroundStyle(PassColor.textNorm.toColor)
                .tint(PassColor.interactionNorm.toColor)
                .frame(height: 64)

            Spacer()
        }
        .padding(.horizontal, DesignConstant.sectionPadding)
        .toolbar { toolbarContent }
        .background(PassColor.backgroundNorm.toColor)
        .onChange(of: viewModel.finishedSaving) { saved in
            guard saved else {
                return
            }
            dismiss()
        }
        .onReceive(viewModel.$creationError) { error in
            showErrorAlert = error != nil
        }
        .alert("Error occurred",
               isPresented: $showErrorAlert,
               actions: {
            Button{ viewModel.creationError = nil } label: {
                       Text("OK")
                   }
               },
               message: {
                   if let message = viewModel.creationError?.localizedDescription {
                       Text(message)
                   }
               })
        .onAppear { focused = true }
        .navigationTitle("Create contact")
        .showSpinner(viewModel.loading)
        .navigationStackEmbeded()
    }
}

private extension CreateContactView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.aliasInteractionNormMajor2,
                         backgroundColor: PassColor.aliasInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Save"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.aliasInteractionNormMajor1,
                                        disableBackgroundColor: PassColor.aliasInteractionNormMinor1,
                                        disabled: !viewModel.canSave,
                                        height: 44,
                                        action: { viewModel.saveContact() })
                .accessibilityLabel("Save")
        }
    }
}
