//
// WordSeparatorsView.swift
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

import SwiftUI
import UIComponents

protocol WordSeparatorsViewModelDelegate: AnyObject {
    func wordSeparatorsViewModelDidSelect(separator: WordSeparator)
}

final class WordSeparatorsViewModel: ObservableObject {
    @Published private(set) var selectedSeparator: WordSeparator

    weak var delegate: WordSeparatorsViewModelDelegate?

    init(selectedSeparator: WordSeparator) {
        self.selectedSeparator = selectedSeparator
    }

    func select(separator: WordSeparator) {
        delegate?.wordSeparatorsViewModelDidSelect(separator: separator)
    }
}

struct WordSeparatorsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: WordSeparatorsViewModel

    init(viewModel: WordSeparatorsViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(WordSeparator.allCases, id: \.self) { separator in
                        row(for: separator)
                        PassDivider()
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: PassColor.backgroundWeak))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Word separator")
                        .navigationTitleText()
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func row(for separator: WordSeparator) -> some View {
        Button(action: {
            viewModel.select(separator: separator)
            dismiss()
        }, label: {
            HStack {
                Text(separator.title)
                Spacer()
                if viewModel.selectedSeparator == separator {
                    Label("", systemImage: "checkmark")
                }
            }
            .padding(.vertical)
            .foregroundColor(Color(uiColor: viewModel.selectedSeparator == separator ?
                                   PassColor.loginInteractionNormMajor2 : PassColor.textNorm))
        })
    }
}
