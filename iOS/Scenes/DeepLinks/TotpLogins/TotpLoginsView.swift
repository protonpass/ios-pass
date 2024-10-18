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
import DesignSystem
import Entities
import Factory
import Macro
import SwiftUI

struct TotpLoginsView: View {
    @StateObject var viewModel: TotpLoginsViewModel
    @FocusState private var isFocusedOnSearchBar
    @Environment(\.dismiss) private var dismiss

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

            if !viewModel.results.isEmpty {
                HStack {
                    Text("Login items")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(PassColor.textNorm.toColor)

                    Spacer()

                    SmallSortTypeButton(selectedSortType: $viewModel.selectedSortType)
                }
                .plainListRow()
                .padding([.horizontal])
                .padding(.bottom, DesignConstant.sectionPadding)
            }

            itemList

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
    }

    var itemList: some View {
        ScrollViewReader { proxy in
            List {
                sortableSections(for: viewModel.results)
            }
            .listStyle(.plain)
            .animation(.default, value: viewModel.results)
            .overlay {
                if viewModel.selectedSortType.isAlphabetical {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy,
                                           direction: viewModel.selectedSortType.sortDirection ?? .ascending)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func sortableSections(for items: [ItemSearchResult]) -> some View {
        switch viewModel.selectedSortType {
        case .mostRecent:
            sections(for: items.mostRecentSortResult())
        case .alphabeticalAsc:
            sections(for: items.alphabeticalSortResult(direction: .ascending))
        case .alphabeticalDesc:
            sections(for: items.alphabeticalSortResult(direction: .descending))
        case .newestToOldest:
            sections(for: items.monthYearSortResult(direction: .descending))
        case .oldestToNewest:
            sections(for: items.monthYearSortResult(direction: .ascending))
        }
    }

    func sections(for result: MostRecentSortResult<ItemSearchResult>) -> some View {
        ForEach(result.buckets) { bucket in
            section(for: bucket.items, headerTitle: bucket.type.title)
        }
    }

    func sections(for result: AlphabeticalSortResult<ItemSearchResult>) -> some View {
        ForEach(result.buckets, id: \.letter) { bucket in
            section(for: bucket.items, headerTitle: bucket.letter.character)
                .id(bucket.letter.character)
        }
    }

    func sections(for result: MonthYearSortResult<ItemSearchResult>) -> some View {
        ForEach(result.buckets, id: \.monthYear) { bucket in
            section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
        }
    }

    @ViewBuilder
    func section(for items: [ItemSearchResult],
                 headerTitle: String,
                 headerColor: UIColor = PassColor.textWeak,
                 headerFontWeight: Font.Weight = .regular) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    ResultItemRow(item: item, selectItem: { viewModel.updateLogin(item: $0) })
                        .plainListRow()
                        .padding(.horizontal)
                        .padding(.vertical, 5)
                }
            }, header: {
                Text(headerTitle)
                    .font(.callout)
                    .fontWeight(headerFontWeight)
                    .foregroundStyle(headerColor.toColor)
            })
        }
    }
}

struct ResultItemRow: View {
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
        }
    }
}

struct SmallSortTypeButton: View {
    @Binding var selectedSortType: SortType

    var body: some View {
        Menu(content: {
            ForEach(SortType.allCases, id: \.self) { type in
                Button(action: {
                    selectedSortType = type
                }, label: {
                    HStack {
                        Text(type.title)
                        Spacer()
                        if type == selectedSortType {
                            Image(systemName: "checkmark")
                        }
                    }
                })
            }
        }, label: sortTypeLabel)
    }

    private func sortTypeLabel() -> some View {
        Label(selectedSortType.title, systemImage: "arrow.up.arrow.down")
            .font(.callout.weight(.medium))
            .foregroundStyle(PassColor.interactionNormMajor2.toColor)
            .animationsDisabled()
    }
}
