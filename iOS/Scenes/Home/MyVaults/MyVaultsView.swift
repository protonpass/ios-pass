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

struct MyVaultsView: View {
    @StateObject private var viewModel: MyVaultsViewModel

    init(viewModel: MyVaultsViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        let coordinator = viewModel.coordinator
        if viewModel.vaults.isEmpty {
            LoadVaultsView(viewModel: .init(coordinator: coordinator))
        } else {
            VaultContentView(viewModel: .init(coordinator: coordinator))
        }
    }
}

struct MyVaultsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyVaultsView(viewModel: .preview)
        }
    }
}
