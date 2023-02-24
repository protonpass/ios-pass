//
// LoadVaultsView.swift
// Proton Pass - Created on 21/07/2022.
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

struct LoadVaultsView: View {
    @StateObject private var viewModel: LoadVaultsViewModel
    @State private var didAppear = false

    init(viewModel: LoadVaultsViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            if let error = viewModel.error {
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: viewModel.getVaults)
                .padding()
            } else {
                LoadingVaultView()
                    .padding()
            }
        }
        .toolbar { toolbarContent }
        .onAppear {
            if !didAppear {
                viewModel.getVaults()
                didAppear = true
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            ToggleSidebarButton(action: viewModel.toggleSidebar)
        }
    }
}
