//
//
// TotpLoginsView.swift
// Proton Pass - Created on 29/01/2024.
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
//

import Client
import Core
import DesignSystem
import Entities
import Factory
import Macro
import Screens
import SwiftUI

struct TotpLoginsView: View {
    @StateObject var viewModel: TotpLoginsViewModel
    @FocusState private var isFocusedOnSearchBar
    @Environment(\.dismiss) private var dismiss

    @AppStorage(Constants.QA.useSwiftUIList, store: kSharedUserDefaults)
    private var useSwiftUIList = false

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()

            mainContainer
                .showSpinner(viewModel.loading)
        }
        .task {
            await viewModel.loadLogins()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Set up 2FA")
        .toolbarBackground(PassColor.backgroundNorm.toColor,
                           for: .navigationBar)
        .navigationStackEmbeded()
        .alert("Associate 2FA?",
               isPresented: $viewModel.showAlert,
               actions: {
                   if let selectedItem = viewModel.selectedItem, !selectedItem.hasTotpUri {
                       Button(action: {
                           viewModel.saveChange()
                       }, label: {
                           Text("Associate and save")
                       })
                   }
                   Button(role: .cancel) {
                       Text("Cancel")
                   }
               }, message: {
                   if let selectedItem = viewModel.selectedItem, !selectedItem.hasTotpUri {
                       Text("Are you sure you want to add a 2FA secret to \"\(selectedItem.title)\"?")
                   } else {
                       Text("This login item already contains a 2FA secret")
                   }
               })
        .onChange(of: viewModel.shouldDismiss) { value in
            if value {
                dismiss()
            }
        }
    }
}

private extension TotpLoginsView {
    var mainContainer: some View {
        VStack(spacing: 0) {
            SearchBar(query: $viewModel.query,
                      isFocused: $isFocusedOnSearchBar,
                      placeholder: "Find login to update",
                      cancelMode: .never,
                      onCancel: { viewModel.clearSearch() })

            switch viewModel.results {
            case .fetching:
                if !viewModel.loading {
                    ProgressView()
                }

            case let .fetched(results):
                if !results.isEmpty {
                    HStack {
                        Text("Login items")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundStyle(PassColor.textNorm.toColor)

                        Spacer()

                        SortTypeButton(selectedSortType: $viewModel.selectedSortType)
                    }
                    .plainListRow()
                    .padding([.horizontal])
                    .padding(.bottom, DesignConstant.sectionPadding)
                }

                if useSwiftUIList {
                    list(results)
                } else {
                    tableView(results)
                }

            case let .error(error):
                RetryableErrorView(error: error,
                                   onRetry: { Task { await viewModel.loadLogins() } })
            }

            Spacer()

            TOTPRow(uri: viewModel.totpUri,
                    tintColor: PassColor.loginInteractionNormMajor2,
                    onCopyTotpToken: { viewModel.copyTotpToken($0) })
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .background(PassColor.loginInteractionNormMinor1.toColor)
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.bottom, 8)

            CapsuleTextButton(title: #localized("Create login"),
                              titleColor: PassColor.loginInteractionNormMajor2,
                              backgroundColor: PassColor.loginInteractionNormMinor1,
                              height: 52,
                              action: { viewModel.createLogin() })
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.results)
    }

    @ViewBuilder
    func tableView(_ results: [SectionedItemSearchResult]) -> some View {
        let sections: [TableView<ItemSearchResult, ResultItemRow, Text>.Section] = results.map {
            .init(type: $0.id, title: $0.sectionTitle, items: $0.items)
        }
        TableView(sections: sections,
                  configuration: .init(showSectionIndexTitles: viewModel.selectedSortType.isAlphabetical),
                  id: nil,
                  itemView: { item in
                      ResultItemRow(item: item,
                                    selectItem: { viewModel.updateLogin(item: $0) })
                  },
                  headerView: { _ in nil })
    }

    func list(_ results: [SectionedItemSearchResult]) -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(results) { result in
                    Section(content: {
                        ForEach(result.items) { item in
                            ResultItemRow(item: item,
                                          selectItem: { viewModel.updateLogin(item: $0) })
                        }
                    }, header: {
                        Text(result.sectionTitle)
                            .font(.callout)
                            .foregroundStyle(PassColor.textWeak.toColor)
                    })
                }
            }
            .listStyle(.plain)
            .overlay {
                if viewModel.selectedSortType.isAlphabetical {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy,
                                           direction: viewModel.selectedSortType.sortDirection)
                    }
                }
            }
        }
    }
}

private struct ResultItemRow: View {
    let item: ItemSearchResult
    let selectItem: (ItemSearchResult) -> Void

    var body: some View {
        Button {
            selectItem(item)
        } label: {
            HStack {
                VStack {
                    ItemSquircleThumbnail(data: item.thumbnailData())
                }
                .frame(maxHeight: .infinity, alignment: .top)

                VStack(alignment: .leading, spacing: 4) {
                    HighlightText(highlightableText: item.highlightableTitle)

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(0..<item.highlightableDetail.count, id: \.self) { index in
                            let eachDetail = item.highlightableDetail[index]
                            if !eachDetail.fullText.isEmpty {
                                HighlightText(highlightableText: eachDetail)
                                    .font(.callout)
                                    .foregroundStyle(Color(.secondaryLabel))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.bottom, 10)
            .contentShape(.rect)
        }
        .plainListRow()
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}
