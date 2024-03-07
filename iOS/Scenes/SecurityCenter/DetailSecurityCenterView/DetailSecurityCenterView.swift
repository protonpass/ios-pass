//
//
// DetailSecurityCenterView.swift
// Proton Pass - Created on 05/03/2024.
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

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

struct SecuritySectionHeaderKey: Hashable, Comparable {
    static func < (lhs: SecuritySectionHeaderKey, rhs: SecuritySectionHeaderKey) -> Bool {
        lhs.title < rhs.title
    }

    let color: Color
    let title: String
    let iconName: String?
}

struct DetailSecurityCenterView: View {
    @StateObject var viewModel: DetailSecurityCenterViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        mainContainer
            .padding(.horizontal, DesignConstant.sectionPadding)
            .navigationTitle(viewModel.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar { toolbarContent }
            .scrollViewEmbeded(maxWidth: .infinity)
            .background(PassColor.backgroundNorm.toColor)
            //            .showSpinner(viewModel.loading)
            .navigationStackEmbeded()
    }
}

private extension DetailSecurityCenterView {
    var mainContainer: some View {
        VStack {
            Text(viewModel.info)
                .foregroundStyle(PassColor.textNorm.toColor)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical)

            LazyVStack(spacing: 0) {
                if viewModel.showSections {
                    itemsSections(sections: viewModel.sectionedData)
                } else {
                    itemsList(items: viewModel.sectionedData.flatMap(\.value))
                }
                Spacer()
            }
        }
    }
}

// MARK: - List of Items

private extension DetailSecurityCenterView {
    func itemsSections(sections: [SecuritySectionHeaderKey: [ItemContent]]) -> some View {
        ForEach(sections.keys.sorted(), id: \.self) { key in
            Section(content: {
                itemsList(items: sections[key] ?? [])
            }, header: {
                Group {
                    if let iconName = key.iconName {
                        Label(key.title, systemImage: iconName)
                    } else {
                        Text(key.title)
                    }
                }.font(.callout)
                    .foregroundColor(key.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            })
        }
    }

    func itemsList(items: [ItemContent]) -> some View {
        ForEach(items) { item in
            itemRow(for: item)
        }
    }

    func itemRow(for item: ItemContent) -> some View {
        Button {
            viewModel.showDetail(item: item)
        } label: {
            GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
                           title: item.title,
                           description: item.toItemUiModel.description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

private extension DetailSecurityCenterView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.chevronDown,
                         iconColor: PassColor.loginInteractionNormMajor2,
                         backgroundColor: PassColor.loginInteractionNormMinor1) {
                dismiss()
            }
        }
    }
}

// struct DetailSecurityCenterView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailSecurityCenterView()
//    }
// }

// import Client
// import Entities
//
// struct GenericCredentialItemRowTest: View {
//    let item: ItemContent
//    let selectItem: (ItemContent) -> Void
//
//    var body: some View {}
// }

//
// VStack(alignment: .leading) {
//    if let lastUsed = viewModel.lastUsedTime {
//        header(lastUsed: lastUsed)
//    }
//
//    if !viewModel.history.isEmpty {
//        historyListView
//    }
//
//    Spacer()
// }
// .animation(.default, value: viewModel.history)
// .padding(.horizontal, DesignConstant.sectionPadding)
// .navigationTitle("History")
// .frame(maxWidth: .infinity, maxHeight: .infinity)
// .toolbar { toolbarContent }
// .scrollViewEmbeded(maxWidth: .infinity)
// .background(PassColor.backgroundNorm.toColor)
// .showSpinner(viewModel.loading)
// .routingProvided
// .navigationStackEmbeded($path)

// func itemRow(for uiModel: ItemUiModel) -> some View {
//    GenericCredentialItemRow(item: uiModel, selectItem: { viewModel.selectedItem = $0 })
// }
//
// public struct LoginItemsView<ItemRow: View, SearchResultRow: View>: View {
//    @StateObject private var viewModel: LoginItemsViewModel
//    @FocusState private var isFocused
//    private let mode: Mode
//    private let itemRow: (ItemUiModel) -> ItemRow
//    private let searchResultRow: (ItemSearchResult) -> SearchResultRow
//    private let onCreate: () -> Void
//    private let onCancel: () -> Void
//
//    public init(searchableItems: [SearchableItem],
//                uiModels: [ItemUiModel],
//                mode: Mode,
//                itemRow: @escaping (ItemUiModel) -> ItemRow,
//                searchResultRow: @escaping (ItemSearchResult) -> SearchResultRow,
//                onCreate: @escaping () -> Void,
//                onCancel: @escaping () -> Void) {
//        _viewModel = .init(wrappedValue: .init(searchableItems: searchableItems,
//                                               uiModels: uiModels))
//        self.mode = mode
//        self.itemRow = itemRow
//        self.searchResultRow = searchResultRow
//        self.onCreate = onCreate
//        self.onCancel = onCancel
//    }
//
//    public var body: some View {
//        VStack {
//            searchBar
//            content
//            if mode.allowCreation {
//                createButton
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(PassColor.backgroundNorm.toColor)
//        .animation(.default, value: viewModel.state)
//    }
// }
//
// private extension LoginItemsView {
//    var searchBar: some View {
//        SearchBar(query: $viewModel.query,
//                  isFocused: $isFocused,
//                  placeholder: mode.searchBarPlaceholder,
//                  onCancel: onCancel)
//    }
//
//    @ViewBuilder
//    var content: some View {
//        switch viewModel.state {
//        case .idle:
//            allItems
//        case .searching:
//            ProgressView()
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//        case let .searchResults(results):
//            if results.isEmpty {
//                NoSearchResultsInAllVaultView(query: viewModel.query)
//            } else {
//                searchResults(results)
//            }
//        }
//    }
//
//    var allItems: some View {
//        List {
//            title
//                .plainListRow()
//
//            description
//                .plainListRow()
//                .padding(.vertical)
//
//            ForEach(viewModel.uiModels) { item in
//                itemRow(item)
//                    .plainListRow()
//            }
//        }
//        .listStyle(.plain)
//        .padding(.horizontal)
//    }
//
//    func searchResults(_ results: [ItemSearchResult]) -> some View {
//        List {
//            ForEach(results) { result in
//                searchResultRow(result)
//                    .plainListRow()
//                    .padding(.top, DesignConstant.sectionPadding)
//            }
//        }
//        .listStyle(.plain)
//        .padding(.horizontal)
//        .animation(.default, value: results.hashValue)
//    }
// }
//
// private extension LoginItemsView {
//    var title: some View {
//        Text(mode.title)
//            .foregroundStyle(PassColor.textNorm.toColor)
//            .font(.title.bold())
//            .frame(maxWidth: .infinity, alignment: .leading)
//    }
//
//    var description: some View {
//        Text(mode.description)
//            .foregroundStyle(PassColor.textNorm.toColor)
//            .font(.headline)
//            .frame(maxWidth: .infinity, alignment: .leading)
//    }
//
//    var createButton: some View {
//        CapsuleTextButton(title: #localized("Create login"),
//                          titleColor: PassColor.loginInteractionNormMajor2,
//                          backgroundColor: PassColor.loginInteractionNormMinor1,
//                          height: 52,
//                          action: onCreate)
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//    }
// }
