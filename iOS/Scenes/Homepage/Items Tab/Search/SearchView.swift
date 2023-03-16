//
// SearchView.swift
// Proton Pass - Created on 13/03/2023.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocusedOnSearchBar: Bool
    @StateObject var viewModel: SearchViewModel
    @State private var safeAreaInsets = EdgeInsets.zero
    @State private var term = ""

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.passBackground
                    .ignoresSafeArea(edges: .all)
                switch viewModel.state {
                case .initializing:
                    SearchViewSkeleton()
                case .clean, .results:
                    content
                case .error(let error):
                    RetryableErrorView(errorMessage: error.messageForTheUser,
                                       onRetry: { Task { await viewModel.loadItems() } })
                }
            }
            .animation(.default, value: viewModel.state)
            .onFirstAppear {
                safeAreaInsets = proxy.safeAreaInsets
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            searchBar

            switch viewModel.state {
            case .clean:
                EmptySearchView()
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, safeAreaInsets.bottom + 200)
            case .results:
                SearchResultsView(selectedType: $viewModel.selectedType,
                                  selectedSortType: $viewModel.selectedSortType,
                                  results: viewModel.filteredResults,
                                  itemCount: viewModel.itemCount,
                                  safeAreaInsets: safeAreaInsets,
                                  onSelectItem: { viewModel.viewDetail(of: $0) },
                                  onSelectSortType: viewModel.presentSortTypeList)
            default:
                // Impossible cases
                EmptyView()
            }

            Spacer()
        }
        .ignoresSafeArea(edges: .bottom)
        .onFirstAppear { isFocusedOnSearchBar = true }
        .onChange(of: term) { term in
            viewModel.search(term)
        }
    }

    private var searchBar: some View {
        HStack {
            ZStack {
                Color.black
                HStack {
                    Image(uiImage: IconProvider.magnifier)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.primary)

                    TextField(viewModel.searchBarPlaceholder, text: $term)
                        .tint(.passBrand)
                        .focused($isFocusedOnSearchBar)
                        .foregroundColor(.primary)

                    Button(action: {
                        term = ""
                    }, label: {
                        Image(uiImage: IconProvider.cross)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.primary)
                    })
                    .buttonStyle(.plain)
                    .opacity(term.isEmpty ? 0 : 1)
                    .animation(.default, value: term.isEmpty)
                }
                .foregroundColor(.textWeak)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .containerShape(Rectangle())

            Button(action: dismiss.callAsFunction) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .foregroundColor(.passBrand)
            }
        }
        .frame(height: kSearchBarHeight)
        .padding()
    }
}
