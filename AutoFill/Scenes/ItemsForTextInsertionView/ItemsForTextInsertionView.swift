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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

struct ItemsForTextInsertionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ItemsForTextInsertionViewModel
    @FocusState private var isFocusedOnSearchBar

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
                              onCancel: { /* Not applicable */ },
                              hideCancel: true)

                    Menu(content: {
                        filterOptions
                        sortOptions
                        if viewModel.resettable {
                            Button(action: { viewModel.resetFilters() },
                                   label: {
                                       Label(title: {
                                           Text("Reset filters")
                                       }, icon: {
                                           IconProvider.crossCircle
                                       })
                                   })
                        }
                    }, label: {
                        CircleButton(icon: IconProvider.threeDotsVertical,
                                     iconColor: viewModel.highlighted ? PassColor.textInvert : PassColor
                                         .interactionNormMajor2,
                                     backgroundColor: viewModel.highlighted ? PassColor
                                         .interactionNormMajor2 : .clear,
                                     accessibilityLabel: "Items filtering and sort menu")
                    })
                }
                .padding(.horizontal)
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
                            Text(verbatim: "Empty")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .padding()
                            Spacer()
                        }
                    } else {
                        itemList
                    }
                }
            case .searching:
                ProgressView()
            case let .searchResults(results):
                EmptyView()
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
    @ViewBuilder
    var sortOptions: some View {
        let sortType = viewModel.sortType
        Menu(content: {
            ForEach(SortType.allCases, id: \.self) { type in
                Button(action: {
                    viewModel.sortType = type
                }, label: {
                    HStack {
                        Text(type.title)
                        Spacer()
                        if type == sortType {
                            Image(systemName: "checkmark")
                        }
                    }
                })
            }
        }, label: {
            Label(title: {
                if #available(iOS 17, *) {
                    Button(action: {}, label: {
                        Text("Sort By")
                        Text(verbatim: sortType.title)
                    })
                } else {
                    Text(verbatim: sortType.title)
                }
            }, icon: {
                Image(uiImage: IconProvider.arrowDownArrowUp)
            })
        })
    }

    @ViewBuilder
    var filterOptions: some View {
        let filterOption = viewModel.filterOption
        let itemCount = viewModel.itemCount
        Menu(content: {
            ForEach(ItemTypeFilterOption.allCases, id: \.self) { option in
                let uiModel = option.uiModel(from: itemCount)
                Button(action: {
                    viewModel.filterOption = option
                }, label: {
                    Label(title: {
                        text(for: uiModel)
                    }, icon: {
                        if option == filterOption {
                            Image(systemName: "checkmark")
                        }
                    })
                })
                // swiftformat:disable:next isEmpty
                .disabled(uiModel.count == 0) // swiftlint:disable:this empty_count
            }
        }, label: {
            Label(title: {
                if #available(iOS 17, *) {
                    // Use Button to trick SwiftUI into rendering option with title and subtitle
                    Button(action: {}, label: {
                        Text("Show")
                        text(for: filterOption.uiModel(from: itemCount))
                    })
                } else {
                    text(for: filterOption.uiModel(from: itemCount))
                }
            }, icon: {
                Image(uiImage: viewModel.highlighted ? PassIcon.filterFilled : IconProvider.filter)
            })
        })
    }

    func text(for uiModel: ItemTypeFilterOptionUiModel) -> some View {
        Text(verbatim: "\(uiModel.title) (\(uiModel.count))")
    }
}

private extension ItemsForTextInsertionView {
    var itemList: some View {
        TableView(sections: viewModel.sections,
                  id: viewModel.selectedUser?.hashValue,
                  itemView: { item in
                      GenericCredentialItemRow(item: item.uiModel,
                                               user: viewModel.getUserForUiDisplay(for: item.uiModel),
                                               selectItem: { viewModel.select($0) })
                  },
                  headerView: { sectionIndex in
                      if let section = viewModel.sections[safeIndex: sectionIndex],
                         section.id.hashValue == ItemsForTextInsertionSectionType.history.hashValue {
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
