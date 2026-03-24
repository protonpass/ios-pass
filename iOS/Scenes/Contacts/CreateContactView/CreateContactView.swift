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
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct CreateContactView: View {
    @State private var viewModel: CreateContactViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused
    let onCreate: (AliasContactLite) -> Void

    init(itemIds: IDs, onCreate: @escaping (AliasContactLite) -> Void) {
        _viewModel = .init(wrappedValue: .init(itemIds: itemIds))
        self.onCreate = onCreate
    }

    var body: some View {
        VStack(spacing: DesignConstant.sectionPadding * 2) {
            TextField("Email address", text: $viewModel.email)
                .focused($focused)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .foregroundStyle(PassColor.textNorm)
                .tint(ItemContentType.alias.normColor)
                .frame(height: 64)

            Spacer()
        }
        .padding(.horizontal)
        .toolbar { toolbarContent }
        .background(PassColor.backgroundNorm)
        .onChange(of: viewModel.createdContact) { _, createdContact in
            if let createdContact {
                onCreate(createdContact)
            }
        }
        .alert("Error occurred",
               isPresented: $viewModel.error.mappedToBool(),
               actions: { Button(action: {}, label: { Text("OK") }) },
               message: {
                   Text(verbatim: viewModel.error?.localizedDescription ?? "")
               })
        .alert("Copy new contact's forwarding address automatically?",
               isPresented: $viewModel.showCopyAfterCreatingAlert,
               actions: {
                   Button(action: { viewModel.dismissCopyAfterCreatingTip(optIn: true) },
                          label: { Text("Yes") })

                   Button(action: { viewModel.dismissCopyAfterCreatingTip(optIn: false) },
                          label: { Text("No") })

                   Button("Cancel", role: .cancel, action: {})
               },
               message: {
                   Text("You can change this anytime in Settings")
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
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.aliasInteractionNormMajor2,
                         backgroundColor: PassColor.aliasInteractionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            DisablableCapsuleTextButton(title: #localized("Create"),
                                        titleColor: PassColor.textInvert,
                                        disableTitleColor: PassColor.textHint,
                                        backgroundColor: PassColor.aliasInteractionNormMajor1,
                                        disableBackgroundColor: PassColor.aliasInteractionNormMinor1,
                                        disabled: !viewModel.canCreate,
                                        height: 44,
                                        action: { viewModel.create() })
                .accessibilityLabel("Create")
        }
    }
}
