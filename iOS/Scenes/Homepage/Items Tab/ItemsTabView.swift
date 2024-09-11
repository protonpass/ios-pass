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
import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI
import TipKit

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel
    @State private var safeAreaInsets = EdgeInsets.zero
    @Namespace private var animationNamespace
    @State private var searchMode: SearchMode?

    @State private var showingTrashAliasAlert = false
    @State private var aliasToTrash: (any ItemTypeIdentifiable)?

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

                itemForceTouchTip

            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: { viewModel.refresh() })
            }
        }
        .animation(.default, value: vaultsManager.state)
        .animation(.default, value: viewModel.shouldShowSyncProgress)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarHidden(true)
    }

    private var fullSyncProgressView: some View {
        FullSyncProgressView(mode: .logIn)
    }

    @ViewBuilder
    private func vaultContent(_ items: [ItemUiModel]) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ItemsTabTopBar(searchMode: $searchMode,
                               animationNamespace: animationNamespace,
                               isEditMode: $viewModel.isEditMode,
                               onSearch: { searchMode = .all(viewModel.vaultsManager.vaultSelection) },
                               onShowVaultList: { viewModel.presentVaultList() },
                               onPin: { viewModel.pinSelectedItems() },
                               onUnpin: { viewModel.unpinSelectedItems() },
                               onMove: { viewModel.presentVaultListToMoveSelectedItems() },
                               onTrash: { viewModel.trashSelectedItems() },
                               onRestore: { viewModel.restoreSelectedItems() },
                               onPermanentlyDelete: { viewModel.askForBulkPermanentDeleteConfirmation() },
                               onDisableAliases: { viewModel.disableSelectedAliases() },
                               onEnableAliases: { viewModel.enableSelectedAliases() })

                if viewModel.showingUpgradeAppBanner {
                    Button(action: { viewModel.openAppOnAppStore() },
                           label: {
                               // swiftlint:disable:next line_length
                               TextBanner("Your current version of the app is no longer supported. Please update to the latest version.")
                                   .padding()
                           })
                }

                if !viewModel.showingUpgradeAppBanner,
                   !viewModel.banners.isEmpty,
                   !viewModel.isEditMode {
                    InfoBannerViewStack(banners: viewModel.banners,
                                        dismiss: { viewModel.dismiss(banner: $0) },
                                        action: { viewModel.handleAction(banner: $0) })
                        .padding()
                }

                if let pinnedItems = viewModel.pinnedItems, !pinnedItems.isEmpty, !viewModel.isEditMode,
                   viewModel.vaultsManager.vaultSelection != .trash {
                    PinnedItemsView(pinnedItems: pinnedItems,
                                    onSearch: { searchMode = .pinned },
                                    action: { viewModel.viewDetail(of: $0) })
                    Divider()
                }

                if items.isEmpty {
                    switch viewModel.vaultsManager.vaultSelection {
                    case .all:
                        EmptyVaultView(canCreateItems: true,
                                       onCreate: { viewModel.createNewItem(type: $0) })
                            .padding(.bottom, safeAreaInsets.bottom)
                    case let .precise(vault):
                        EmptyVaultView(canCreateItems: vault.canEdit,
                                       onCreate: { viewModel.createNewItem(type: $0) })
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
            .animation(.default, value: viewModel.pinnedItems)
            .animation(.default, value: viewModel.isEditMode)
            .animation(.default, value: viewModel.showingUpgradeAppBanner)
            .task {
                await viewModel.loadPinnedItems()
            }
            .onFirstAppear {
                safeAreaInsets = proxy.safeAreaInsets
                viewModel.continueFullSyncIfNeeded()
            }
            .alert("Move to Trash", isPresented: $showingTrashAliasAlert) {
                if let aliasToTrash, aliasToTrash.aliasEnabled {
                    Button("Disable instead") {
                        viewModel.itemContextMenuHandler.disableAlias(aliasToTrash)
                    }
                }
                Button("Move to Trash") {
                    if let aliasToTrash {
                        viewModel.itemContextMenuHandler.trash(aliasToTrash)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let aliasToTrash, aliasToTrash.aliasEnabled {
                    // swiftlint:disable:next line_length
                    Text("Aliases in Trash will continue forwarding emails. If you want to stop receiving emails on this address, disable it instead.")
                }
            }
        }
        .searchScreen(searchMode: $searchMode, animationNamespace: animationNamespace)
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
                     onRefresh: viewModel.forceSyncIfNotEditMode)
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
                         onRefresh: viewModel.forceSyncIfNotEditMode)
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
                     onRefresh: viewModel.forceSyncIfNotEditMode)
    }

    @ViewBuilder
    func section(for items: [ItemUiModel], headerTitle: String) -> some View {
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
                    .foregroundStyle(PassColor.textWeak.toColor)
            })
        }
    }

    @ViewBuilder
    func itemRow(for item: ItemUiModel) -> some View {
        let isTrashed = viewModel.vaultsManager.vaultSelection == .trash
        let isEditable = viewModel.isEditable(item)
        let isSelected = viewModel.isSelected(item)
        Button(action: {
            viewModel.handleSelection(item)
        }, label: {
            GeneralItemRow(thumbnailView: {
                               if viewModel.isEditMode, isSelected {
                                   SquircleCheckbox()
                               } else {
                                   ItemSquircleThumbnail(data: item.thumbnailData(),
                                                         isEnabled: item.isAlias ? item.isAliasEnabled : true,
                                                         pinned: item.pinned)
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
                                         isEditable: isEditable,
                                         onPermanentlyDelete: { viewModel.itemToBePermanentlyDeleted = item },
                                         onAliasTrash: {
                                             aliasToTrash = item
                                             showingTrashAliasAlert.toggle()
                                         },
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
                                    isEditable: isEditable,
                                    itemContextMenuHandler: viewModel.itemContextMenuHandler))
        .modifier(PermenentlyDeleteItemModifier(isShowingAlert: $viewModel.showingPermanentDeletionAlert,
                                                onDelete: viewModel.permanentlyDelete))
        .disabled(!isEditable && viewModel.isEditMode)
    }
}

private struct ItemsTabsSkeleton: View {
    var body: some View {
        VStack {
            HStack {
                SkeletonBlock()
                    .frame(width: DesignConstant.searchBarHeight)
                    .clipShape(Circle())

                SkeletonBlock()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(height: DesignConstant.searchBarHeight)
            .shimmering()

            HStack {
                SkeletonBlock()
                    .frame(width: 60)
                    .clipShape(Capsule())

                Spacer()

                SkeletonBlock()
                    .frame(width: 150)
                    .clipShape(Capsule())
            }
            .frame(height: 18)
            .frame(maxWidth: .infinity)
            .shimmering()

            HStack {
                SkeletonBlock()
                    .frame(width: 100, height: 18)
                    .clipShape(Capsule())
                Spacer()
            }
            .shimmering()

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
            SkeletonBlock()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading) {
                Spacer()
                SkeletonBlock()
                    .frame(width: 170, height: 10)
                    .clipShape(Capsule())
                Spacer()
                SkeletonBlock()
                    .frame(width: 200, height: 10)
                    .clipShape(Capsule())
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shimmering()
    }
}

private extension ItemsTabView {
    @ViewBuilder
    var itemForceTouchTip: some View {
        if #available(iOS 17, *) {
            VStack {
                Spacer()
                TipView(ItemForceTouchTip())
                    .passTipView()
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
