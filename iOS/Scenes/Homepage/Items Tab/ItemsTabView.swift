//
// ItemsTabView.swift
// Proton Pass - Created on 07/03/2023.
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

import Client
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel
    @State private var safeAreaInsets = EdgeInsets.zero
    @State private var itemToBePermanentlyDeleted: ItemTypeIdentifiable?

    var body: some View {
        let vaultsManager = viewModel.vaultsManager
        ZStack {
            switch vaultsManager.state {
            case .loading:
                ItemsTabsSkeleton()

            case .loaded:
                switch vaultsManager.vaultSelection {
                case .all:
                    vaultContent(vaultsManager.getItem(for: .all))
                case .precise(let selectedVault):
                    vaultContent(vaultsManager.getItem(for: .precise(selectedVault)))
                case .trash:
                    vaultContent(vaultsManager.getItem(for: .trash))
                }

            case .error(let error):
                RetryableErrorView(errorMessage: error.messageForTheUser,
                                   onRetry: viewModel.vaultsManager.refresh)
            }
        }
        .animation(.default, value: vaultsManager.state)
        .background(Color(uiColor: PassColor.backgroundNorm))
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func vaultContent(_ items: [ItemUiModel]) -> some View {
        GeometryReader { proxy in
            VStack {
                topBar
                if items.isEmpty {
                    switch viewModel.vaultsManager.vaultSelection {
                    case .all, .precise:
                        EmptyVaultView(viewModel: viewModel.emptyVaultViewModel)
                            .padding(.bottom, safeAreaInsets.bottom)
                    case .trash:
                        EmptyTrashView()
                            .padding(.bottom, safeAreaInsets.bottom)
                    }
                } else {
                    itemList(items)
                    Spacer()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .edgesIgnoringSafeArea(.bottom)
            .animation(.default, value: viewModel.vaultsManager.state)
            .onFirstAppear {
                safeAreaInsets = proxy.safeAreaInsets
            }
        }
    }

    private var topBar: some View {
        HStack {
            switch viewModel.vaultsManager.vaultSelection {
            case .all:
                CircleButton(
                    icon: PassIcon.allVaults,
                    iconColor: PassColor.loginInteractionNormMajor2,
                    backgroundColor: PassColor.loginInteractionNormMajor2.withAlphaComponent(0.16),
                    type: .big,
                    action: viewModel.presentVaultList)
                .frame(width: kSearchBarHeight)

            case .precise(let vault):
                CircleButton(
                    icon: vault.displayPreferences.icon.icon.image,
                    iconColor: vault.displayPreferences.color.color.color,
                    backgroundColor: vault.displayPreferences.color.color.color.withAlphaComponent(0.16),
                    action: viewModel.presentVaultList)
                .frame(width: kSearchBarHeight)

            case .trash:
                CircleButton(icon: IconProvider.trash,
                             iconColor: PassColor.textWeak,
                             backgroundColor: PassColor.textDisabled,
                             action: viewModel.presentVaultList)
                .frame(width: kSearchBarHeight)
            }

            ZStack {
                Color(uiColor: PassColor.backgroundStrong)
                HStack {
                    Image(uiImage: IconProvider.magnifier)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(viewModel.vaultsManager.vaultSelection.searchBarPlacehoder)
                }
                .foregroundColor(Color(uiColor: PassColor.textWeak))
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
            .onTapGesture(perform: viewModel.search)
        }
        .padding(.horizontal)
        .frame(height: kSearchBarHeight)
    }

    @ViewBuilder
    private func itemList(_ items: [ItemUiModel]) -> some View {
        HStack {
            Text("All")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(Color(uiColor: PassColor.textNorm)) +
            Text(" (\(items.count))")
                .font(.callout)
                .foregroundColor(Color(uiColor: PassColor.textWeak))

            Spacer()

            SortTypeButton(selectedSortType: $viewModel.selectedSortType,
                           action: viewModel.presentSortTypeList)
        }
        .padding([.top, .horizontal])

        switch viewModel.selectedSortType {
        case .mostRecent:
            itemList(items.mostRecentSortResult())
        case .alphabetical:
            itemList(items.alphabeticalSortResult())
        case .newestToOldest:
            itemList(items.monthYearSortResult(direction: .descending))
        case .oldestToNewest:
            itemList(items.monthYearSortResult(direction: .ascending))
        }
    }

    private func itemList(_ result: MostRecentSortResult<ItemUiModel>) -> some View {
        ItemListView(
            safeAreaInsets: safeAreaInsets,
            content: {
                section(for: result.today, headerTitle: "Today")
                section(for: result.yesterday, headerTitle: "Yesterday")
                section(for: result.last7Days, headerTitle: "Last week")
                section(for: result.last14Days, headerTitle: "Last two weeks")
                section(for: result.last30Days, headerTitle: "Last 30 days")
                section(for: result.last60Days, headerTitle: "Last 60 days")
                section(for: result.last90Days, headerTitle: "Last 90 days")
                section(for: result.others, headerTitle: "More than 90 days")
            },
            onRefresh: viewModel.forceSync)
    }

    private func itemList(_ result: AlphabeticalSortResult<ItemUiModel>) -> some View {
        ScrollViewReader { proxy in
            ItemListView(
                safeAreaInsets: safeAreaInsets,
                showScrollIndicators: false,
                content: {
                    ForEach(result.buckets, id: \.letter) { bucket in
                        section(for: bucket.items, headerTitle: bucket.letter.character)
                            .id(bucket.letter.character)
                    }
                },
                onRefresh: viewModel.forceSync)
            .overlay {
                HStack {
                    Spacer()
                    SectionIndexTitles(proxy: proxy)
                }
            }
        }
    }

    private func itemList(_ result: MonthYearSortResult<ItemUiModel>) -> some View {
        ItemListView(
            safeAreaInsets: safeAreaInsets,
            content: {
                ForEach(result.buckets, id: \.monthYear) { bucket in
                    section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
                }
            },
            onRefresh: viewModel.forceSync)
    }

    @ViewBuilder
    private func section(for items: [ItemUiModel], headerTitle: String) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    itemRow(for: item)
                        .plainListRow()
                }
            }, header: {
                Text(headerTitle)
                    .font(.callout)
                    .foregroundColor(Color(uiColor: PassColor.textWeak))
            })
        }
    }

    @ViewBuilder
    private func itemRow(for item: ItemUiModel) -> some View {
        let permanentlyDeleteBinding = Binding<Bool>(get: {
            itemToBePermanentlyDeleted != nil
        }, set: { newValue in
            if !newValue {
                itemToBePermanentlyDeleted = nil
            }
        })

        let isTrashed = viewModel.vaultsManager.vaultSelection == .trash
        Button(action: {
            viewModel.viewDetail(of: item)
        }, label: {
            GeneralItemRow(
                thumbnailView: {
                    SquircleThumbnail(icon: item.type.icon,
                                      iconColor: item.type.normMajor1Color,
                                      backgroundColor: item.type.normMinor1Color)
                },
                title: item.title,
                description: item.description)
            .itemContextMenu(item: item,
                             isTrashed: isTrashed,
                             onPermanentlyDelete: { itemToBePermanentlyDeleted = item },
                             handler: viewModel.itemContextMenuHandler)
        })
        .padding(.horizontal, 16)
        .frame(height: 64)
        .modifier(ItemSwipeModifier(
            itemToBePermanentlyDeleted: $itemToBePermanentlyDeleted,
            item: item,
            isTrashed: isTrashed,
            itemContextMenuHandler: viewModel.itemContextMenuHandler))
        .modifier(PermenentlyDeleteItemModifier(
            isShowingAlert: permanentlyDeleteBinding,
            onDelete: {
                if let itemToBePermanentlyDeleted {
                    viewModel.itemContextMenuHandler.deletePermanently(itemToBePermanentlyDeleted)
                }
            }))
    }
}

private struct ItemsTabsSkeleton: View {
    var body: some View {
        VStack {
            HStack {
                AnimatingGradient()
                    .frame(width: kSearchBarHeight)
                    .clipShape(Circle())

                AnimatingGradient()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(height: kSearchBarHeight)

            HStack {
                AnimatingGradient()
                    .frame(width: 60)
                    .clipShape(Capsule())

                Spacer()

                AnimatingGradient()
                    .frame(width: 150)
                    .clipShape(Capsule())
            }
            .frame(height: 18)
            .frame(maxWidth: .infinity)

            HStack {
                AnimatingGradient()
                    .frame(width: 100, height: 18)
                    .clipShape(Capsule())
                Spacer()
            }

            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(0..<20, id: \.self) { _ in
                        itemRow
                    }
                }
            }
            .disabled(true)
        }
        .padding(.horizontal)
    }

    private var itemRow: some View {
        HStack(spacing: 16) {
            AnimatingGradient()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading) {
                Spacer()
                AnimatingGradient()
                    .frame(width: 170, height: 10)
                    .clipShape(Capsule())
                Spacer()
                AnimatingGradient()
                    .frame(width: 200, height: 10)
                    .clipShape(Capsule())
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ItemListView<Content: View>: View {
    let safeAreaInsets: EdgeInsets
    let showScrollIndicators: Bool
    let content: () -> Content
    let onRefresh: @Sendable () async -> Void

    init(safeAreaInsets: EdgeInsets,
         showScrollIndicators: Bool = true,
         @ViewBuilder content: @escaping () -> Content,
         onRefresh: @Sendable @escaping () async -> Void) {
        self.safeAreaInsets = safeAreaInsets
        self.showScrollIndicators = showScrollIndicators
        self.content = content
        self.onRefresh = onRefresh
    }

    var body: some View {
        List {
            content()
            Spacer()
                .frame(height: safeAreaInsets.bottom)
                .plainListRow()
        }
        .listStyle(.plain)
        .scrollIndicatorsHidden(!showScrollIndicators)
        .refreshable(action: onRefresh)
    }
}
