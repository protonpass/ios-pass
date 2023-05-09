//
// PasswordTypesView.swift
// Proton Pass - Created on 09/05/2023.
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

import Core
import SwiftUI
import UIComponents

protocol PasswordTypesViewModelDelegate: AnyObject {
    func passwordTypesViewModelDidSelect(type: PasswordType)
}

final class PasswordTypesViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var selectedType: PasswordType

    weak var delegate: PasswordTypesViewModelDelegate?

    init(selectedType: PasswordType) {
        self.selectedType = selectedType
    }

    func select(type: PasswordType) {
        delegate?.passwordTypesViewModelDidSelect(type: type)
    }
}

struct PasswordTypesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PasswordTypesViewModel

    init(viewModel: PasswordTypesViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(PasswordType.allCases, id: \.self) { type in
                        row(for: type)
                        PassDivider()
                    }
                }
            }
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: PassColor.backgroundWeak))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Password type")
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func row(for type: PasswordType) -> some View {
        Button(action: {
            if viewModel.selectedType != type {
                viewModel.select(type: type)
            }
            dismiss()
        }, label: {
            HStack {
                Text(type.title)
                Spacer()
                if viewModel.selectedType == type {
                    Label("", systemImage: "checkmark")
                }
            }
            .padding(.vertical)
            .foregroundColor(Color(uiColor: viewModel.selectedType == type ?
                                   PassColor.loginInteractionNormMajor2 : PassColor.textNorm) )
        })
    }
}
