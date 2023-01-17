//
// VaultListView.swift
// Proton Pass - Created on 28/12/2022.
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

struct VaultListView: View {
    @ObservedObject var viewModel: VaultListViewModel

    var body: some View {
        NavigationView {
            Form {
                ForEach(viewModel.vaults, id: \.id) { vault in
                    HStack {
                        if vault.id == viewModel.selectedVault?.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.interactionNorm)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading) {
                            Text(vault.name)
                            Text(vault.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .swipeActions {
                        Button(action: {
                            viewModel.deleteVault(vault)
                        }, label: {
                            Text("Delete")
                        })
                        .tint(.red)
                    }
                    .onTapGesture {
                        if vault.id != viewModel.selectedVault?.id {
                            viewModel.selectVault(vault)
                        }
                    }
                }
            }
            .navigationTitle("My vaults")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: viewModel.createVault) {
                Image(uiImage: IconProvider.plus)
            }
            .foregroundColor(.primary)
        }
    }
}
