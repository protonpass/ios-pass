//
// OneTimeCodesView.swift
// Proton Pass - Created on 18/09/2024.
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

import DesignSystem
import SwiftUI

struct OneTimeCodesView: View {
    @StateObject private var viewModel: OneTimeCodesViewModel
    @FocusState private var isFocusedOnSearchBar

    init(viewModel: OneTimeCodesViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded:
                ScrollView {
                    LazyVStack {
                        Text(verbatim: "Matched")
                        ForEach(viewModel.matchedItems) { item in
                            Text(item.title)
                        }

                        Text(verbatim: "Not Matched")
                        ForEach(viewModel.notMatchedItems) { item in
                            Text(item.title)
                        }
                    }
                }
            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: { Task { await viewModel.fetchItems() } })
            }
        }
        .task {
            await viewModel.fetchItems()
            await viewModel.sync(ignoreError: true)
        }
    }
}
