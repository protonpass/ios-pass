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

let kSearchBarHeight: CGFloat = 48

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel
    @State private var safeAreaInsets = EdgeInsets.zero
    @State private var toBeTrashedItem: ItemUiModel?
    @State private var isShowingDeleteConfirmation = false

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
        .background(Color.passBackground)
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func vaultContent(_ items: [ItemUiModel]) -> some View {
        let isShowingTrashingAlert = Binding<Bool>(get: {
            toBeTrashedItem != nil
        }, set: { newValue in
            if !newValue {
                toBeTrashedItem = nil
            }
        })

        GeometryReader { proxy in
            VStack {
                topBar
                if items.isEmpty {
                    switch viewModel.vaultsManager.vaultSelection {
                    case .all:
                        // Impossible case
                        EmptyView()
                    case .precise:
                        EmptyVaultView(onCreateNewItem: viewModel.createNewItem)
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
            .moveToTrashAlert(isPresented: isShowingTrashingAlert) {
                if let toBeTrashedItem {
                    viewModel.trash(toBeTrashedItem)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            switch viewModel.vaultsManager.vaultSelection {
            case .all:
                CircleButton(icon: PassIcon.allVaults,
                             color: .passBrand,
                             backgroundOpacity: 0.16,
                             action: viewModel.presentVaultList)
                .frame(width: kSearchBarHeight)

            case .precise(let vault):
                CircleButton(icon: vault.displayPreferences.icon.icon.image,
                             color: vault.displayPreferences.color.color.color,
                             backgroundOpacity: 0.16,
                             action: viewModel.presentVaultList)
                .frame(width: kSearchBarHeight)

            case .trash:
                CircleButton(icon: IconProvider.trash,
                             color: .textWeak,
                             backgroundOpacity: 0.16,
                             action: viewModel.presentVaultList)
                .frame(width: kSearchBarHeight)
            }

            ZStack {
                Color.black
                HStack {
                    Image(uiImage: IconProvider.magnifier)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(viewModel.vaultsManager.vaultSelection.searchBarPlacehoder)
                }
                .foregroundColor(.textWeak)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .containerShape(Rectangle())
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
                .fontWeight(.bold) +
            Text(" (\(items.count))")
                .font(.callout)
                .foregroundColor(.textWeak)

            Spacer()

            SortTypeButton(selectedSortType: $viewModel.selectedSortType,
                           action: viewModel.presentSortTypeList)
        }
        .padding(.horizontal)

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
                    SectionIndexTitles(proxy: proxy, titles: result.buckets.map { $0.letter.character })
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
                }
            }, header: {
                Text(headerTitle)
            })
        }
    }

    @ViewBuilder
    private func itemRow(for item: ItemUiModel) -> some View {
        let isTrashed = viewModel.vaultsManager.vaultSelection == .trash
        Button(action: {
            viewModel.viewDetail(of: item)
        }, label: {
            GeneralItemRow(
                thumbnailView: {
                    switch item.type {
                    case .alias:
                        CircleButton(icon: IconProvider.alias,
                                     color: ItemContentType.alias.tintColor) {}
                    case .login:
                        CircleButton(icon: IconProvider.keySkeleton,
                                     color: ItemContentType.login.tintColor) {}
                    case .note:
                        CircleButton(icon: IconProvider.notepadChecklist,
                                     color: ItemContentType.note.tintColor) {}
                    }
                },
                title: item.title,
                description: item.description)
        })
        .listRowSeparator(.hidden)
        .listRowInsets(.zero)
        .padding(.horizontal, 16)
        .listRowBackground(Color.clear)
        .frame(height: 64)
        .swipeActions(edge: .leading) {
            leadingSwipeActions(for: item,
                                isTrashed: isTrashed,
                                itemContextMenuHandler: viewModel.itemContextMenuHandler)
        }
        .swipeActions(edge: .trailing) {
            trailingSwipeActions(for: item, isTrashed: isTrashed)
        }
        .itemContextMenu(item: item,
                         isTrashed: isTrashed,
                         isShowingDeleteConfirmation: $isShowingDeleteConfirmation,
                         handler: viewModel.itemContextMenuHandler)
    }

    @ViewBuilder
    private func leadingSwipeActions(for item: ItemUiModel,
                                     isTrashed: Bool,
                                     itemContextMenuHandler: ItemContextMenuHandler) -> some View {
        if isTrashed {
            Button(action: {
                itemContextMenuHandler.untrash(item)
            }, label: {
                Label(title: {
                    Text("Restore")
                }, icon: {
                    Image(uiImage: IconProvider.clockRotateLeft)
                })
            })
            .tint(.notificationSuccess)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func trailingSwipeActions(for item: ItemUiModel, isTrashed: Bool) -> some View {
        if isTrashed {
            Button(action: {
                isShowingDeleteConfirmation.toggle()
            }, label: {
                Label(title: {
                    Text("Permanently delete")
                }, icon: {
                    Image(uiImage: IconProvider.trash)
                })
            })
            .tint(Color(uiColor: .init(red: 252, green: 156, blue: 159)))
        } else {
            Button(action: {
                askForConfirmationOrTrashDirectly(item: item)
            }, label: {
                Label(title: {
                    Text("Trash")
                }, icon: {
                    Image(uiImage: IconProvider.trash)
                })
            })
            .tint(Color(uiColor: .init(red: 252, green: 156, blue: 159)))
        }
    }

    private func askForConfirmationOrTrashDirectly(item: ItemUiModel) {
        if viewModel.preferences.askBeforeTrashing {
            toBeTrashedItem = item
        } else {
            viewModel.trash(item)
        }
    }
}

private struct ItemsTabsSkeleton: View {
    var body: some View {
        VStack {
            HStack {
                AnimatingGradient()
                    .frame(width: kSearchBarHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                AnimatingGradient()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(height: kSearchBarHeight)

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
                .clipShape(Circle())

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
                .listRowSeparator(.hidden)
                .listRowInsets(.zero)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollIndicatorsHidden(!showScrollIndicators)
        .refreshable(action: onRefresh)
    }
}
