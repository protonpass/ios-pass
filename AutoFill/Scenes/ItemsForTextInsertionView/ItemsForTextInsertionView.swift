//
// ItemsForTextInsertionView.swift
// Proton Pass - Created on 27/09/2024.
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

import DesignSystem
import Entities
import Macro
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct ItemsForTextInsertionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ItemsForTextInsertionViewModel
    @FocusState private var isFocusedOnSearchBar
    @State private var showItemTypeList = false

    init(viewModel: ItemsForTextInsertionViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            stateViews
        }
        .task {
            await viewModel.fetchItems()
            viewModel.filterAndSortItems()
            await viewModel.sync(ignoreError: true)
        }
        .localAuthentication(onSuccess: { _ in viewModel.handleAuthenticationSuccess() },
                             onFailure: { _ in viewModel.handleAuthenticationFailure() })
        .optionalSheet(binding: $viewModel.selectedItem) { selectedItem in
            ItemDetailView(item: selectedItem,
                           selectedTextStream: viewModel.selectedTextStream)
                .environment(\.colorScheme, colorScheme)
        }
        .sheet(isPresented: $showItemTypeList) {
            ItemTypeListView(viewModel: .init(mode: .autoFillExtension,
                                              onSelect: { type in
                                                  viewModel.selectedItemType = type
                                                  if viewModel.shouldAskForUserWhenCreatingNewItem {
                                                      viewModel.presentSelectUserActionSheet()
                                                  } else {
                                                      viewModel.createNewItem(userId: nil)
                                                  }
                                              }))
                                              .presentationDetents([.height(200)])
                                              .environment(\.colorScheme, colorScheme)
        }
    }
}

private extension ItemsForTextInsertionView {
    var stateViews: some View {
        VStack(spacing: 0) {
            if viewModel.state != .loading {
                HStack(spacing: 0) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Close",
                                 action: { viewModel.handleCancel() })

                    SearchBar(query: $viewModel.query,
                              isFocused: $isFocusedOnSearchBar,
                              placeholder: viewModel.searchBarPlaceholder,
                              cancelMode: .never)

                    if viewModel.query.isEmpty {
                        SortFilterItemsMenu(options: [
                            .filter(viewModel.filterOption,
                                    viewModel.itemCount) { viewModel.filterOption = $0 },
                            .sort(viewModel.selectedSortType) { viewModel.selectedSortType = $0 },
                            .resetFilters { viewModel.resetFilters() }
                        ],
                        highlighted: viewModel.highlighted,
                        selectable: false,
                        resettable: viewModel.resettable)
                    }
                }
                .padding(.horizontal)
                .animation(.default, value: viewModel.query.isEmpty)
            }
            switch viewModel.state {
            case .idle:
                if viewModel.users.count > 1 {
                    UserAccountSelectionMenu(selectedUser: $viewModel.selectedUser,
                                             users: viewModel.users)
                        .padding(.horizontal)
                }

                if viewModel.isFreeUser {
                    MainVaultsOnlyBanner(onTap: { viewModel.upgrade() })
                        .padding([.horizontal, .top])
                }

                if !viewModel.results.isEmpty {
                    if viewModel.sections.allSatisfy(\.items.isEmpty) {
                        VStack {
                            Spacer()
                            Text("Empty")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .padding()
                            Spacer()
                        }
                    } else {
                        itemList
                    }
                }

                HStack {
                    CapsuleLabelButton(icon: IconProvider.plus,
                                       title: #localized("Create"),
                                       titleColor: PassColor.interactionNormMajor2,
                                       backgroundColor: PassColor.interactionNormMinor1,
                                       maxWidth: nil,
                                       action: { showItemTypeList.toggle() })
                    Spacer()
                }
                .padding([.horizontal, .top])

            case .searching:
                ProgressView()

            case let .searchResults(results):
                if results.isEmpty {
                    NoSearchResultsInAllVaultView(query: viewModel.query)
                } else {
                    CredentialSearchResultView(results: results,
                                               selectedSortType: $viewModel.selectedSortType,
                                               getUser: { viewModel.getUserForUiDisplay(for: $0) },
                                               selectItem: { viewModel.select($0) })
                }

            case .loading:
                CredentialsSkeletonView()

            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
                                   onRetry: { Task { await viewModel.fetchItems() } })
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.selectedUser)
        .animation(.default, value: viewModel.results)
    }
}

private extension ItemsForTextInsertionView {
    var itemList: some View {
        TableView(sections: viewModel.sections,
                  configuration: .init(showSectionIndexTitles: viewModel.selectedSortType.isAlphabetical),
                  id: viewModel.selectedUser?.hashValue,
                  itemView: { item in
                      GenericCredentialItemRow(item: item.uiModel,
                                               user: viewModel.getUserForUiDisplay(for: item.uiModel),
                                               selectItem: { viewModel.select($0) })
                  },
                  headerView: { sectionIndex in
                      if let section = viewModel.sections[safeIndex: sectionIndex],
                         section.type.hashValue == ItemsForTextInsertionSectionType.history.hashValue {
                          TextInsertionHistoryHeaderView {
                              viewModel.clearHistory()
                          }
                      } else {
                          nil
                      }
                  })
                  .padding(.top)
    }
}

struct TextInsertionHistoryHeaderView: View {
    let onClear: () -> Void

    var body: some View {
        HStack {
            Text("Recents")
                .font(.callout.bold())
                .foregroundStyle(PassColor.textNorm.toColor)
            Spacer()
            Button(action: onClear) {
                Text("Clear")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .underline(color: PassColor.textWeak.toColor)
            }
        }
    }
}
