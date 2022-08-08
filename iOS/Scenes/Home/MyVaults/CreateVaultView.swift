//
// CreateVaultView.swift
// Proton Pass - Created on 07/07/2022.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct CreateVaultView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: CreateVaultViewModel

    init(viewModel: CreateVaultViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TitledTextField(title: "Name",
                                placeholder: "Vault name",
                                text: $viewModel.name,
                                contentType: .singleLine,
                                isRequired: false,
                                trailingView: { EmptyView() })

                TitledTextField(title: "Note",
                                placeholder: "Add description",
                                text: $viewModel.note,
                                contentType: .multiline,
                                isRequired: false,
                                trailingView: { EmptyView() })
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Cancel")
                    })
                    .foregroundColor(Color(.label))
                }

                ToolbarItem(placement: .principal) {
                    Text("Create new vault")
                        .fontWeight(.bold)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.createVault) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(Color(ColorProvider.BrandNorm))
                            .opacity(viewModel.name.isEmpty ? 0.5 : 1)
                    }
                    .disabled(viewModel.name.isEmpty)
                }
            }
        }
        .disabled(viewModel.isLoading)
    }
}

struct CreateVaultView_Previews: PreviewProvider {
    static var previews: some View {
        CreateVaultView(viewModel: .preview)
    }
}
