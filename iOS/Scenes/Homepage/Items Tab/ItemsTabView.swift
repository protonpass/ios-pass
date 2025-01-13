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
import ProtonCoreUIFoundations
import Screens
import SwiftUI
import TipKit

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel
    @State private var safeAreaInsets = EdgeInsets.zero
    @Namespace private var animationNamespace
    @State private var searchMode: SearchMode?

    @State private var aliasToTrash: (any ItemTypeIdentifiable)?

    @State private var showSharedItemsAlert = false

    @AppStorage(Constants.QA.useSwiftUIList, store: kSharedUserDefaults)
    private var useSwiftUIList = false

    var body: some View {
        ZStack {
            switch viewModel.sectionedItems {
            case .fetching:
                // We display both the skeleton and the progress at the same time
                // and use opacity trick because we need fullSyncProgressView
                // to be intialized asap so its viewModel doesn't miss any events
                fullSyncProgressView
                    .opacity(viewModel.shouldShowSyncProgress ? 1 : 0)
                ItemsTabsSkeleton()
                    .opacity(viewModel.shouldShowSyncProgress ? 0 : 1)

            case let .fetched(sections):
                if viewModel.shouldShowSyncProgress {
                    fullSyncProgressView
                } else {
                    vaultContent(sections)
                }

                itemForceTouchTip
                Spacer()

            case let .error(error):
                RetryableErrorView(error: error, onRetry: viewModel.refresh)
            }
        }
        .animation(.default, value: viewModel.sectionedItems)
        .animation(.default, value: viewModel.shouldShowSyncProgress)
        .background(PassColor.backgroundNorm.toColor)
        .navigationBarHidden(true)
        .onChange(of: viewModel.filterOption) { _ in
            viewModel.filterAndSortItems()
        }
        .onChange(of: viewModel.selectedSortType) { type in
            viewModel.filterAndSortItems(sortType: type)
        }
        .alert("Moving items", isPresented: $showSharedItemsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Move") {
                viewModel.presentVaultListToMoveSelectedItems()
            }
        } message: {
            // swiftlint:disable:next line_length
            Text("At least one of the selected items is currently shared. Moving it to another vault will remove access for all other users.")
        }
    }

    private var fullSyncProgressView: some View {
        FullSyncProgressView(mode: .logIn)
    }

    @ViewBuilder
    private func vaultContent(_ sections: [SectionedItemUiModel]) -> some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                ItemsTabTopBar(searchMode: $searchMode,
                               animationNamespace: animationNamespace,
                               isEditMode: $viewModel.isEditMode,
                               onSearch: { searchMode = .all(viewModel.appContentManager.vaultSelection) },
                               onShowVaultList: { viewModel.presentVaultList() },
                               onPin: { viewModel.pinSelectedItems() },
                               onUnpin: { viewModel.unpinSelectedItems() },
                               onMove: {
                                   if viewModel.hasSharedItems() {
                                       showSharedItemsAlert.toggle()
                                   } else {
                                       viewModel.presentVaultListToMoveSelectedItems()
                                   }
                               },
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
                   viewModel.appContentManager.vaultSelection != .trash {
                    PinnedItemsView(pinnedItems: pinnedItems,
                                    onSearch: { searchMode = .pinned },
                                    action: { viewModel.viewDetail(of: $0) })
                    Divider()
                }

                if sections.isEmpty {
                    emptySections
                } else {
                    itemList(sections)
                    Spacer()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .edgesIgnoringSafeArea(.bottom)
            .animation(.default, value: viewModel.appContentManager.state)
            .animation(.default, value: viewModel.appContentManager.filterOption)
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
            .modifier(PermenentlyDeleteItemModifier(item: $viewModel.itemToBePermanentlyDeleted,
                                                    onDisableAlias: { viewModel.disableAlias() },
                                                    onDelete: { viewModel.permanentlyDelete() }))
        }
        .searchScreen(searchMode: $searchMode, animationNamespace: animationNamespace)
    }
}

private extension ItemsTabView {
    @ViewBuilder
    var emptySections: some View {
        switch viewModel.appContentManager.vaultSelection {
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
        case .sharedByMe, .sharedWithMe:
            VStack {
                Spacer()
                Text(viewModel.appContentManager
                    .vaultSelection == .sharedByMe ? "You have not shared any items" :
                    "No items are shared with you")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.vertical)
                    .foregroundStyle(PassColor.textNorm.toColor)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, safeAreaInsets.bottom)
        }
    }

    @ViewBuilder
    func itemList(_ sections: [SectionedItemUiModel]) -> some View {
        if useSwiftUIList {
            ScrollViewReader { proxy in
                ItemListView(safeAreaInsets: safeAreaInsets,
                             content: {
                                 ForEach(sections) { section in
                                     Section(content: {
                                         ForEach(section.items) { item in
                                             itemRow(item)
                                         }
                                     }, header: {
                                         Text(section.sectionTitle)
                                             .font(.callout)
                                             .foregroundStyle(PassColor.textWeak.toColor)
                                             .frame(maxWidth: .infinity, alignment: .leading)
                                     })
                                     .id(section.id)
                                 }
                             },
                             onRefresh: viewModel.forceSyncIfNotEditMode)
                    .if(viewModel.selectedSortType.isAlphabetical) { view in
                        view.overlay {
                            HStack {
                                Spacer()
                                SectionIndexTitles(proxy: proxy,
                                                   direction: viewModel.selectedSortType.sortDirection)
                            }
                        }
                    }
            }
        } else {
            let sections: [TableView<ItemUiModel, ItemRow, Text>.Section] = sections.map { section in
                .init(type: section.id,
                      title: section.sectionTitle,
                      items: section.items)
            }
            TableView(sections: sections,
                      configuration: .init(showSectionIndexTitles: viewModel.selectedSortType
                          .isAlphabetical,
                          rowSpacing: 8),
                      // Force reload rows when bulk selecting
                      id: viewModel.currentSelectedItems.value.hashValue,
                      itemView: { itemRow($0) },
                      headerView: { _ in nil },
                      onRefresh: viewModel.forceSyncIfNotEditMode)
        }
    }

    @ViewBuilder
    func itemRow(_ item: ItemUiModel) -> ItemRow {
        let isTrashed = viewModel.appContentManager.vaultSelection == .trash
        let isEditable = viewModel.isEditable(item)
        let isSelected = viewModel.isSelected(item)
        ItemRow(item: item,
                isEditMode: viewModel.isEditMode,
                isEditable: isEditable,
                isSelected: isSelected,
                isTrashed: isTrashed,
                aliasSyncEnabled: viewModel.aliasSyncEnabled,
                onSelectThumbnail: { viewModel.handleThumbnailSelection(item) },
                onSelectItem: { viewModel.handleSelection(item) },
                itemToBePermanentlyDeleted: $viewModel.itemToBePermanentlyDeleted,
                onPermanentlyDelete: { viewModel.permanentlyDelete() },
                onAliasTrash: {
                    if viewModel.aliasSyncEnabled {
                        aliasToTrash = item
                    } else {
                        viewModel.itemContextMenuHandler.trash(item)
                    }
                },
                itemContextMenuHandler: viewModel.itemContextMenuHandler)
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
    let itemToBePermanentlyDeleted: Binding<(any ItemTypeIdentifiable)?>
    let onPermanentlyDelete: () -> Void
    let onAliasTrash: () -> Void
    let itemContextMenuHandler: ItemContextMenuHandler

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
                           description: item.description,
                           isShared: item.isShared)
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
        .disabled(!isEditable && isEditMode)
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
        .listRowBackground(Color.clear)
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
