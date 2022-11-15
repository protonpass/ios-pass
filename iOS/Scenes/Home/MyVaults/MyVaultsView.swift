//
// MyVaultsView.swift
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

import SwiftUI
import UIComponents

struct MyVaultsView: View {
    @StateObject private var viewModel: MyVaultsViewModel
    private let loadVaultsViewModel: LoadVaultsViewModel
    private let vaultContentViewModel: VaultContentViewModel

    init(myVaultsViewModel: MyVaultsViewModel,
         loadVaultsViewModel: LoadVaultsViewModel,
         vaultContentViewModel: VaultContentViewModel) {
        _viewModel = .init(wrappedValue: myVaultsViewModel)
        self.loadVaultsViewModel = loadVaultsViewModel
        self.vaultContentViewModel = vaultContentViewModel
    }

    var body: some View {
        if viewModel.vaults.isEmpty {
            LoadVaultsView(viewModel: loadVaultsViewModel)
        } else {
            VaultContentView(viewModel: vaultContentViewModel)
        }
    }
}
