//
// CreateAliasLiteView.swift
// Proton Pass - Created on 16/02/2023.
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

import SwiftUI
import UIComponents

struct CreateAliasLiteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateAliasLiteViewModel

    init(viewModel: CreateAliasLiteViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack {}
                }

                HStack {
                    CapsuleTextButton(title: "Cancel",
                                      titleColor: .textWeak,
                                      backgroundColor: .white.withAlphaComponent(0.08),
                                      height: 44,
                                      action: dismiss.callAsFunction)

                    CapsuleTextButton(title: "Confirm",
                                      titleColor: .systemBackground,
                                      backgroundColor: .brandNorm,
                                      height: 44,
                                      action: viewModel.confirm)
                }
                .padding(.horizontal)
            }
            .navigationTitle("You are about to create")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
