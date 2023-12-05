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
            VStack(spacing: 0) {
                ItemsTabTopBar(isEditMode: $viewModel.isEditMode,
                               onSearch: viewModel.search,
                               onShowVaultList: viewModel.presentVaultList,
                               onMove: viewModel.presentVaultListToMoveSelectedItems,
                               onTrash: viewModel.trashSelectedItems,
                               onRestore: viewModel.restoreSelectedItems,
                               onPermanentlyDelete: viewModel.askForBulkPermanentDeleteConfirmation)

                if !viewModel.banners.isEmpty, !viewModel.isEditMode {
                    InfoBannerViewStack(banners: viewModel.banners,
                                        dismiss: viewModel.dismiss(banner:),
                                        action: viewModel.handleAction(banner:))
                        .padding([.horizontal, .top])
                }

                if items.isEmpty {
                    switch viewModel.vaultsManager.vaultSelection {
                    case .all, .precise:
                        EmptyVaultView(onCreate: viewModel.createNewItem(type:))
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
            .animation(.default, value: viewModel.vaultsManager.filterOption)
            .animation(.default, value: viewModel.banners.count)
            .onFirstAppear {
                safeAreaInsets = proxy.safeAreaInsets
            }
        }
    }

    @ViewBuilder
    private func itemList(_ items: [ItemUiModel]) -> some View {
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

    private func itemList(_ result: MostRecentSortResult<ItemUiModel>) -> some View {
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
                     onRefresh: viewModel.forceSyncIfNotEditMode)
    }

    private func itemList(_ result: AlphabeticalSortResult<ItemUiModel>,
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
                         onRefresh: viewModel.forceSyncIfNotEditMode)
                .overlay {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy, direction: direction)
                    }
                }
        }
    }

    private func itemList(_ result: MonthYearSortResult<ItemUiModel>) -> some View {
        ItemListView(safeAreaInsets: safeAreaInsets,
                     content: {
                         ForEach(result.buckets, id: \.monthYear) { bucket in
                             section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
                         }
                     },
                     onRefresh: viewModel.forceSyncIfNotEditMode)
    }

    @ViewBuilder
    private func section(for items: [ItemUiModel], headerTitle: String) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    itemRow(for: item)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 4, leading: -10, bottom: 4, trailing: -10))
                        .listRowBackground(Color.clear)
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
        let isTrashed = viewModel.vaultsManager.vaultSelection == .trash
        let isSelectable = viewModel.isSelectable(item)
        let isSelected = viewModel.isSelected(item)
        Button(action: {
            viewModel.handleSelection(item)
        }, label: {
            GeneralItemRow(thumbnailView: {
                               if viewModel.isEditMode, isSelected {
                                   SquircleCheckbox()
                               } else {
                                   ItemSquircleThumbnail(data: item.thumbnailData())
                                       .onTapGesture {
                                           viewModel.handleThumbnailSelection(item)
                                       }
                               }
                           },
                           title: item.title,
                           description: item.description)
                .if(!viewModel.isEditMode) { view in
                    view.itemContextMenu(item: item,
                                         isTrashed: isTrashed,
                                         onPermanentlyDelete: { viewModel.itemToBePermanentlyDeleted = item },
                                         handler: viewModel.itemContextMenuHandler)
                }
                .padding(.horizontal)
                .background(isSelected ? PassColor.interactionNormMinor1.toColor : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .animation(.default, value: isSelected)
        })
        .padding(.horizontal, 16)
        .frame(height: 64)
        .modifier(ItemSwipeModifier(itemToBePermanentlyDeleted: $viewModel.itemToBePermanentlyDeleted,
                                    item: item,
                                    isEditMode: viewModel.isEditMode,
                                    isTrashed: isTrashed,
                                    itemContextMenuHandler: viewModel.itemContextMenuHandler))
        .modifier(PermenentlyDeleteItemModifier(isShowingAlert: $viewModel.showingPermanentDeletionAlert,
                                                onDelete: viewModel.permanentlyDelete))
        .disabled(!isSelectable && viewModel.isEditMode)
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
