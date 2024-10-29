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
import Screens
import SwiftUI
import TipKit

// swiftlint:disable:next todo
// TODO: Remove later on after using the same UI component to render item list
private let kListThreshold = 500

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel
    @State private var safeAreaInsets = EdgeInsets.zero
    @Namespace private var animationNamespace
    @State private var searchMode: SearchMode?

    @State private var aliasToTrash: (any ItemTypeIdentifiable)?

    @AppStorage(Constants.QA.useSwiftUIList, store: kSharedUserDefaults)
    private var useSwiftUIList = false

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

            case let .loaded(uiModel):
//                if viewModel.shouldShowSyncProgress {
//                    fullSyncProgressView
//                } else {
//                    vaultContent(vaultsManager.getFilteredItems())
//                }
//
//                itemForceTouchTip

                let sections: [TableView<ItemUiModel, Text, Text>.Section] = [
                    .init(type: "", title: "", items: uiModel.vaults.flatMap(\.items))
                ]
                TableView(sections: sections,
                          configuration: .init(),
                          id: sections.hashValue,
                          itemView: { item in
                              Text(item.title)
                          },
                          headerView: { _ in nil })
                Spacer()

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
            .if(viewModel.aliasSyncEnabled) {
                $0.modifier(AliasTrashAlertModifier(showingTrashAliasAlert: $aliasToTrash.mappedToBool(),
                                                    enabled: aliasToTrash?.aliasEnabled ?? false,
                                                    disableAction: {
                                                        if let aliasToTrash {
                                                            viewModel.itemContextMenuHandler
                                                                .disableAlias(aliasToTrash)
                                                        }
                                                    },
                                                    trashAction: {
                                                        if let aliasToTrash {
                                                            viewModel.itemContextMenuHandler.trash(aliasToTrash)
                                                        }
                                                    }))
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
                     mode: result.numberOfItems > kListThreshold ? .lazyVStack : .list,
                     content: {
                         ForEach(result.buckets) { bucket in
                             section(for: bucket.items,
                                     headerTitle: bucket.type.title,
                                     totalItemsCount: result.numberOfItems)
                         }
                     },
                     onRefresh: viewModel.forceSyncIfNotEditMode)
    }

    func itemList(_ result: AlphabeticalSortResult<ItemUiModel>,
                  direction: SortDirection) -> some View {
        ScrollViewReader { proxy in
            ItemListView(safeAreaInsets: safeAreaInsets,
                         showScrollIndicators: false,
                         mode: result.numberOfItems > kListThreshold ? .lazyVStack : .list,
                         content: {
                             ForEach(result.buckets, id: \.letter) { bucket in
                                 section(for: bucket.items,
                                         headerTitle: bucket.letter.character,
                                         totalItemsCount: result.numberOfItems)
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
                     mode: result.numberOfItems > kListThreshold ? .lazyVStack : .list,
                     content: {
                         ForEach(result.buckets, id: \.monthYear) { bucket in
                             section(for: bucket.items,
                                     headerTitle: bucket.monthYear.relativeString,
                                     totalItemsCount: result.numberOfItems)
                         }
                     },
                     onRefresh: viewModel.forceSyncIfNotEditMode)
    }

    @ViewBuilder
    func section(for items: [ItemUiModel],
                 headerTitle: String,
                 totalItemsCount: Int) -> some View {
        let isListMode = totalItemsCount <= kListThreshold
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    itemRow(for: item, isListMode: isListMode)
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 4, leading: -10, bottom: 4, trailing: -10))
                        .listRowBackground(Color.clear)
                }
            }, header: {
                Text(headerTitle)
                    .font(.callout)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, isListMode ? 0 : 20)
                    .padding(.vertical, isListMode ? 0 : 4)
                    .if(!isListMode) {
                        $0.background(.ultraThinMaterial)
                    }
            })
        }
    }

    @ViewBuilder
    func itemRow(for item: ItemUiModel, isListMode: Bool) -> some View {
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
                                         aliasSyncEnabled: viewModel.aliasSyncEnabled,
                                         onPermanentlyDelete: { viewModel.itemToBePermanentlyDeleted = item },
                                         onAliasTrash: {
                                             if viewModel.aliasSyncEnabled {
                                                 aliasToTrash = item
                                             } else {
                                                 viewModel.itemContextMenuHandler.trash(item)
                                             }
                                         },
                                         handler: viewModel.itemContextMenuHandler)
                }
                .padding(.horizontal)
                .background(isSelected ? PassColor.interactionNormMinor1.toColor : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .animation(.default, value: isSelected)
        })
        .if(isListMode) {
            $0.padding(.horizontal, 16)
        }
        .frame(height: 64)
        .modifier(ItemSwipeModifier(itemToBePermanentlyDeleted: $viewModel.itemToBePermanentlyDeleted,
                                    item: item,
                                    isEditMode: viewModel.isEditMode,
                                    isTrashed: isTrashed,
                                    isEditable: isEditable,
                                    itemContextMenuHandler: viewModel.itemContextMenuHandler,
                                    aliasSyncEnabled: viewModel.aliasSyncEnabled))
        .modifier(PermenentlyDeleteItemModifier(isShowingAlert: $viewModel.showingPermanentDeletionAlert,
                                                onDelete: viewModel.permanentlyDelete))
        .disabled(!isEditable && viewModel.isEditMode)
    }
}

private struct ItemRow: View {
    let item: ItemUiModel
    let isEditMode: Bool
    let isEditable: Bool
    let isSelected: Bool
    let isTrashed: Bool
    let aliasSyncEnabled: Bool
    let onSelectThumbnail: () -> Void
    let onSelectItem: () -> Void
    let onPermanentlyDelete: () -> Void
    let onAliasTrash: () -> Void
    let itemContextMenuHandler: ItemContextMenuHandler
    let itemToBePermanentlyDeleted: Binding<(any ItemTypeIdentifiable)?>

    var body: some View {
        Button(action: onSelectItem) {
            GeneralItemRow(thumbnailView: {
                               if isEditMode, isSelected {
                                   SquircleCheckbox()
                               } else {
                                   ItemSquircleThumbnail(data: item.thumbnailData(),
                                                         isEnabled: item.isAlias ? item.isAliasEnabled : true,
                                                         pinned: item.pinned)
                                       .onTapGesture(perform: onSelectThumbnail)
                               }
                           },
                           title: item.title,
                           description: item.description)
                .if(!isEditMode) { view in
                    view.itemContextMenu(item: item,
                                         isTrashed: isTrashed,
                                         isEditable: isEditable,
                                         aliasSyncEnabled: aliasSyncEnabled,
                                         onPermanentlyDelete: onPermanentlyDelete,
                                         onAliasTrash: onAliasTrash,
                                         handler: itemContextMenuHandler)
                }
                .padding(.horizontal)
                .background(isSelected ? PassColor.interactionNormMinor1.toColor : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .animation(.default, value: isSelected)
        }
        .frame(height: 64)
        .modifier(ItemSwipeModifier(itemToBePermanentlyDeleted: itemToBePermanentlyDeleted,
                                    item: item,
                                    isEditMode: isEditMode,
                                    isTrashed: isTrashed,
                                    isEditable: isEditable,
                                    itemContextMenuHandler: itemContextMenuHandler,
                                    aliasSyncEnabled: aliasSyncEnabled))
//        .modifier(PermenentlyDeleteItemModifier(isShowingAlert: $viewModel.showingPermanentDeletionAlert,
//                                                onDelete: viewModel.permanentlyDelete))
        .disabled(!isEditable && isEditMode)
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
    enum Mode {
        case list, lazyVStack
    }

    let safeAreaInsets: EdgeInsets
    let showScrollIndicators: Bool
    let mode: Mode
    let content: () -> Content
    let onRefresh: @Sendable () async -> Void

    init(safeAreaInsets: EdgeInsets,
         showScrollIndicators: Bool = true,
         mode: Mode,
         @ViewBuilder content: @escaping () -> Content,
         onRefresh: @Sendable @escaping () async -> Void) {
        self.safeAreaInsets = safeAreaInsets
        self.showScrollIndicators = showScrollIndicators
        self.mode = mode
        self.content = content
        self.onRefresh = onRefresh
    }

    var body: some View {
        switch mode {
        case .list:
            List {
                content()
                Spacer()
                    .frame(height: safeAreaInsets.bottom)
                    .plainListRow()
            }
            .listStyle(.plain)
            .scrollIndicatorsHidden(!showScrollIndicators)
            .refreshable(action: onRefresh)

        case .lazyVStack:
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    content()
                    Spacer()
                        .frame(height: safeAreaInsets.bottom)
                        .plainListRow()
                }
            }
            .scrollIndicatorsHidden(!showScrollIndicators)
            .refreshable(action: onRefresh)
        }
    }
}
