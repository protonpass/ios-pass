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
import Core
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel
    @State private var safeAreaInsets = EdgeInsets.zero

    var body: some View {
        let vaultsManager = viewModel.vaultsManager
        ZStack {
            switch vaultsManager.state {
            case .loading:
                // We display both the skeleton and the progress at the same time
                // and use opacity trick because we need fullSyncProgressView
                // to be intialized asap so its viewModel doesn't miss any events
                fullSyncProgressView
                    .opacity(viewModel.shouldShowSyncProgress ? 1 : 0)
                ItemsTabsSkeleton()
                    .opacity(viewModel.shouldShowSyncProgress ? 0 : 1)

            case .loaded:
                if viewModel.shouldShowSyncProgress {
                    fullSyncProgressView
                } else {
                    vaultContent(vaultsManager.getFilteredItems())
                }

            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: viewModel.vaultsManager.refresh)
            }
        }
        .animation(.default, value: vaultsManager.state)
        .animation(.default, value: viewModel.shouldShowSyncProgress)
        .background(Color(uiColor: PassColor.backgroundNorm))
        .navigationBarHidden(true)
    }

    private var fullSyncProgressView: some View {
        FullSyncProgressView(mode: .logIn) {
            viewModel.shouldShowSyncProgress = false
        }
    }

    @ViewBuilder
    private func vaultContent(_ items: [ItemUiModel]) -> some View {
        GeometryReader { proxy in
            VStack {
                topBar

                if !viewModel.banners.isEmpty {
                    InfoBannerViewStack(banners: viewModel.banners,
                                        dismiss: { viewModel.dismiss(banner: $0) },
                                        action: { viewModel.handleAction(banner: $0) })
                        .padding([.horizontal, .top])
                }

                if let pinnedItems = viewModel.pinnedItems, !pinnedItems.isEmpty {
                    pinnedItemsView(with: pinnedItems)
                    Divider()
                }

                if items.isEmpty {
                    emptyViews
                } else {
                    itemList(items)
                    Spacer()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .edgesIgnoringSafeArea(.bottom)
            .animation(.default, value: viewModel.vaultsManager.state)
            .animation(.default, value: viewModel.vaultsManager.filterOption)
            .animation(.default, value: viewModel.banners.count)
            .onFirstAppear {
                safeAreaInsets = proxy.safeAreaInsets
            }
        }
    }
}

// MARK: - Top Bar

private extension ItemsTabView {
    var topBar: some View {
        HStack {
            switch viewModel.vaultsManager.vaultSelection {
            case .all:
                CircleButton(icon: PassIcon.brandPass,
                             iconColor: VaultSelection.all.color,
                             backgroundColor: VaultSelection.all.color.withAlphaComponent(0.16),
                             type: .big,
                             action: viewModel.presentVaultList)
                    .frame(width: kSearchBarHeight)

            case let .precise(vault):
                CircleButton(icon: vault.displayPreferences.icon.icon.bigImage,
                             iconColor: vault.displayPreferences.color.color.color,
                             backgroundColor: vault.displayPreferences.color.color.color.withAlphaComponent(0.16),
                             action: viewModel.presentVaultList)
                    .frame(width: kSearchBarHeight)

            case .trash:
                CircleButton(icon: IconProvider.trash,
                             iconColor: VaultSelection.trash.color,
                             backgroundColor: VaultSelection.trash.color.withAlphaComponent(0.16),
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundColor(Color(uiColor: PassColor.textWeak))
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
            .onTapGesture { viewModel.search() }
        }
        .padding(.horizontal)
        .frame(height: kSearchBarHeight)
    }
}

// MARK: - Pinned Items

private extension ItemsTabView {
    func pinnedItemsView(with pinnedItems: [ItemUiModel]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 8) {
                ForEach(pinnedItems) { item in
                    Button {
                        viewModel.viewDetail(of: item)
                    } label: {
                        HStack(alignment: .center, spacing: 8) {
                            ItemSquircleThumbnail(data: item.thumbnailData(),
                                                  size: .small,
                                                  alternativeBackground: true)
                            Text(item.title)
                                .font(.body)
                                .lineLimit(1)
                                .foregroundColor(PassColor.textNorm.toColor)
                                .padding(.trailing, 8)
                        }
                        .padding(8)
                        .frame(maxWidth: 164, alignment: .leading)
                        .background(item.type.normMinor1Color.toColor)
                        .cornerRadius(16)
                    }
                }

                Button {
                    viewModel.search(pinnedItems: true)
                } label: {
                    Text("See all")
                        .font(.callout.weight(.medium))
                        .foregroundColor(PassColor.interactionNormMajor2.toColor)
                        .padding(.trailing, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
        }
    }
}

// MARK: - Empty View

private extension ItemsTabView {
    @ViewBuilder
    var emptyViews: some View {
        switch viewModel.vaultsManager.vaultSelection {
        case .all, .precise:
            EmptyVaultView(onCreate: viewModel.createNewItem(type:))
                .padding(.bottom, safeAreaInsets.bottom)
        case .trash:
            EmptyTrashView()
                .padding(.bottom, safeAreaInsets.bottom)
        }
    }
}

// MARK: - Items list

private extension ItemsTabView {
    @ViewBuilder
    func itemList(_ items: [ItemUiModel]) -> some View {
        HStack {
            ItemTypeFilterButton(itemCount: viewModel.vaultsManager.itemCount,
                                 selectedOption: viewModel.vaultsManager.filterOption,
                                 onSelect: viewModel.vaultsManager.updateItemTypeFilterOption,
                                 onTap: viewModel.showFilterOptions)

            Spacer()

            SortTypeButton(selectedSortType: $viewModel.selectedSortType,
                           action: viewModel.presentSortTypeList)
        }
        .padding([.top, .horizontal])

        switch viewModel.selectedSortType {
        case .mostRecent:
            itemList(items.mostRecentSortResult())
        case .alphabeticalAsc:
            itemList(items.alphabeticalSortResult(direction: .ascending), direction: .ascending)
        case .alphabeticalDesc:
            itemList(items.alphabeticalSortResult(direction: .descending), direction: .descending)
        case .newestToOldest:
            itemList(items.monthYearSortResult(direction: .descending))
        case .oldestToNewest:
            itemList(items.monthYearSortResult(direction: .ascending))
        }
    }

    func itemList(_ result: MostRecentSortResult<ItemUiModel>) -> some View {
        ItemListView(safeAreaInsets: safeAreaInsets,
                     content: {
                         section(for: result.today, headerTitle: #localized("Today"))
                         section(for: result.yesterday, headerTitle: #localized("Yesterday"))
                         section(for: result.last7Days, headerTitle: #localized("Last week"))
                         section(for: result.last14Days, headerTitle: #localized("Last two weeks"))
                         section(for: result.last30Days, headerTitle: #localized("Last 30 days"))
                         section(for: result.last60Days, headerTitle: #localized("Last 60 days"))
                         section(for: result.last90Days, headerTitle: #localized("Last 90 days"))
                         section(for: result.others, headerTitle: #localized("More than 90 days"))
                     },
                     onRefresh: viewModel.forceSync)
    }

    func itemList(_ result: AlphabeticalSortResult<ItemUiModel>,
                  direction: SortDirection) -> some View {
        ScrollViewReader { proxy in
            ItemListView(safeAreaInsets: safeAreaInsets,
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
                        SectionIndexTitles(proxy: proxy, direction: direction)
                    }
                }
        }
    }

    func itemList(_ result: MonthYearSortResult<ItemUiModel>) -> some View {
        ItemListView(safeAreaInsets: safeAreaInsets,
                     content: {
                         ForEach(result.buckets, id: \.monthYear) { bucket in
                             section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
                         }
                     },
                     onRefresh: viewModel.forceSync)
    }

    @ViewBuilder
    func section(for items: [ItemUiModel], headerTitle: String) -> some View {
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
    func itemRow(for item: ItemUiModel) -> some View {
        let isTrashed = viewModel.vaultsManager.vaultSelection == .trash
        Button(action: {
            viewModel.viewDetail(of: item)
        }, label: {
            GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: item.thumbnailData()) },
                           title: item.title,
                           description: item.description)
                .itemContextMenu(item: item,
                                 isTrashed: isTrashed,
                                 onPermanentlyDelete: { viewModel.itemToBePermanentlyDeleted = item },
                                 handler: viewModel.itemContextMenuHandler)
        })
        .padding(.horizontal, 16)
        .frame(height: 64)
        .modifier(ItemSwipeModifier(itemToBePermanentlyDeleted: $viewModel.itemToBePermanentlyDeleted,
                                    item: item,
                                    isTrashed: isTrashed,
                                    itemContextMenuHandler: viewModel.itemContextMenuHandler))
        .modifier(PermenentlyDeleteItemModifier(isShowingAlert: $viewModel.showingPermanentDeletionAlert,
                                                onDelete: viewModel.permanentlyDelete))
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
