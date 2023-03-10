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
import SwipeActions
import UIComponents

private let kTopBarHeight: CGFloat = 48

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel
    @State private var safeAreaInsets = EdgeInsets.zero
    @State private var toBeTrashedItem: ItemListUiModelV2?
    @State private var state: SwipeState = .untouched

    var body: some View {
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

                switch viewModel.vaultsManager.state {
                case .loading:
                    ProgressView()

                case .loaded:
                    VStack {
                        HStack {
                            Text("All")
                                .font(.callout)
                                .fontWeight(.bold) +
                            Text(" (\(viewModel.vaultsManager.itemCount))")
                                .font(.callout)
                                .foregroundColor(.textWeak)

                            Spacer()

                            sortTypeButton
                        }
                        .padding(.horizontal)

                        let items = viewModel.vaultsManager.getSelectedVaultItems()
                        switch viewModel.selectedSortType {
                        case .mostRecent:
                            itemList(items.mostRecentSortResult())
                        case .alphabetical:
                            itemList(items.alphabeticalSortResult())
                        case .newestToNewest:
                            itemList(items.monthYearSortResult(direction: .descending))
                        case .oldestToNewest:
                            itemList(items.monthYearSortResult(direction: .ascending))
                        }
                    }
                    .animation(.default, value: viewModel.vaultsManager.state)

                case .error(let error):
                    RetryableErrorView(errorMessage: error.messageForTheUser,
                                       onRetry: viewModel.vaultsManager.refresh)
                }
                Spacer()
            }
            .background(Color.passBackground)
            .edgesIgnoringSafeArea(.bottom)
            .onFirstAppear {
                safeAreaInsets = proxy.safeAreaInsets
            }
            .moveToTrashAlert(isPresented: isShowingTrashingAlert) {
                if let toBeTrashedItem {
                    viewModel.trash(item: toBeTrashedItem)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: viewModel.presentVaultList) {
                ZStack {
                    Color.passBrand
                        .opacity(0.16)
                    Image(uiImage: IconProvider.vault)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.passBrand)
                        .padding(kTopBarHeight / 4)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(width: kTopBarHeight)

            ZStack {
                Color.black
                HStack {
                    Image(uiImage: IconProvider.magnifier)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16)
                    Text("Search in all vaults...")
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
        .frame(height: kTopBarHeight)
    }

    @ViewBuilder
    private var sortTypeButton: some View {
        if UIDevice.current.isIpad {
            Menu(content: {
                ForEach(SortTypeV2.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.selectedSortType = type
                    }, label: {
                        HStack {
                            Text(type.title)
                            Spacer()
                            if type == viewModel.selectedSortType {
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: sortTypeLabel)
        } else {
            Button(action: viewModel.presentSortTypeList,
                   label: sortTypeLabel)
        }
    }

    private func sortTypeLabel() -> some View {
        Label(viewModel.selectedSortType.title, systemImage: "arrow.up.arrow.down")
            .font(.callout.weight(.medium))
            .foregroundColor(.passBrand)
            .transaction { transaction in
                transaction.animation = nil
            }
    }

    private func itemList(_ result: MostRecentSortResult<ItemListUiModelV2>) -> some View {
        ItemListScrollView(safeAreaInsets: safeAreaInsets) {
            section(for: result.today, headerTitle: "Today")
            section(for: result.yesterday, headerTitle: "Yesterday")
            section(for: result.last7Days, headerTitle: "Last week")
            section(for: result.last14Days, headerTitle: "Last two weeks")
            section(for: result.last30Days, headerTitle: "Last 30 days")
            section(for: result.last60Days, headerTitle: "Last 60 days")
            section(for: result.last90Days, headerTitle: "Last 90 days")
            section(for: result.others, headerTitle: "More than 90 days")
        }
    }

    private func itemList(_ result: AlphabeticalSortResult<ItemListUiModelV2>) -> some View {
        ItemListScrollView(safeAreaInsets: safeAreaInsets) {
            ForEach(result.buckets, id: \.letter) { bucket in
                section(for: bucket.items, headerTitle: bucket.letter.character)
            }
        }
    }

    private func itemList(_ result: MonthYearSortResult<ItemListUiModelV2>) -> some View {
        ItemListScrollView(safeAreaInsets: safeAreaInsets) {
            ForEach(result.buckets, id: \.monthYear) { bucket in
                section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
            }
        }
    }

    @ViewBuilder
    private func section(for items: [ItemListUiModelV2], headerTitle: String) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    itemRow(for: item)
                }
            }, header: {
                Text(headerTitle)
                    .font(.caption)
                    .foregroundColor(.textWeak)
                    .padding(.vertical, 4)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.passBackground)
            })
        }
    }

    private func itemRow(for item: ItemListUiModelV2) -> some View {
        Button(action: {
            collapseSwipeActions()
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
            .frame(height: 64)
            .padding(.horizontal)
            .addSwipeAction(edge: .trailing, state: $state) {
                Button(action: {
                    collapseSwipeActions()
                    askForConfirmationOrTrashDirectly(item: item)
                }, label: {
                    VStack(spacing: 4) {
                        Spacer()
                        Image(uiImage: IconProvider.trash)
                        Text("Trash")
                            .font(.caption)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .foregroundColor(Color(uiColor: .systemBackground))
                    .frame(width: 84)
                    .background(Color.notificationError)
                })
            }
        })
        .buttonStyle(.plain)
    }

    private func askForConfirmationOrTrashDirectly(item: ItemListUiModelV2) {
        if viewModel.preferences.askBeforeTrashing {
            toBeTrashedItem = item
        } else {
            viewModel.trash(item: item)
        }
    }

    private func collapseSwipeActions() {
        state = .swiped(UUID())
    }
}

private struct ItemListScrollView<Content: View>: View {
    let safeAreaInsets: EdgeInsets
    let content: () -> Content

    init(safeAreaInsets: EdgeInsets,
         @ViewBuilder content: @escaping () -> Content) {
        self.safeAreaInsets = safeAreaInsets
        self.content = content
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                content()
            }
            .padding(.bottom, safeAreaInsets.bottom)
        }
    }
}
