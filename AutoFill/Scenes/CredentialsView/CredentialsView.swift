//
// CredentialsView.swift
// Proton Pass - Created on 27/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

struct CredentialsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: CredentialsViewModel
    @FocusState private var isFocusedOnSearchBar

    init(viewModel: CredentialsViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            PassColor.backgroundNorm
                .ignoresSafeArea()

            if viewModel.showNoPasskeys {
                NoPasskeysView(onCancel: viewModel.handleCancel)
            } else {
                stateViews
            }
        }
        .task {
            await viewModel.fetchItems()
            await viewModel.sync(ignoreError: true)
        }
        .localAuthentication(logOutButtonMode: .topBarTrailing { viewModel.handleCancel() },
                             onSuccess: { _ in viewModel.handleAuthenticationSuccess() },
                             onFailure: { _ in viewModel.handleAuthenticationFailure() })
        .alert("Associate URL?",
               isPresented: $viewModel.notMatchedItemInformation.mappedToBool(),
               actions: {
                   if let information = viewModel.notMatchedItemInformation {
                       Button(action: {
                           viewModel.associateAndAutofill(item: information.item)
                       }, label: {
                           Text("Associate and autofill")
                       })

                       Button(action: {
                           viewModel.select(item: information.item, skipUrlAssociationCheck: true)
                       }, label: {
                           Text("Just autofill")
                       })
                   }

                   Button(role: .cancel) {
                       Text("Cancel")
                   }
               },
               message: {
                   if let information = viewModel.notMatchedItemInformation {
                       Text(verbatim: #localized("Would you want to associate \"%1$@\" with \"%2$@\"?",
                                                 information.url, information.item.itemTitle))
                   }
               })
        .sheet(isPresented: selectPasskeySheetBinding) {
            if let info = viewModel.selectPasskeySheetInformation,
               let context = viewModel.context {
                SelectPasskeyView(info: info, context: context)
                    .presentationDetents([.height(CGFloat(info.passkeys.count * 60) + 80)])
                    .environment(\.colorScheme, colorScheme)
            }
        }
    }
}

private extension CredentialsView {
    var stateViews: some View {
        VStack(spacing: 0) {
            if viewModel.state != .loading {
                SearchBar(query: $viewModel.query,
                          isFocused: $isFocusedOnSearchBar,
                          placeholder: viewModel.searchBarPlaceholder,
                          cancelMode: .always,
                          onCancel: { viewModel.handleCancel() })
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
                    if viewModel.matchedItems.isEmpty,
                       viewModel.notMatchedItemSections.fetchedObject?.isEmpty == true {
                        VStack {
                            Spacer()
                            Text(viewModel.mode.emptyMessage)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(PassColor.textNorm)
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
                if results.isEmpty {
                    NoSearchResultsView(query: viewModel.query)
                } else {
                    CredentialSearchResultView(results: results,
                                               selectedSortType: $viewModel.selectedSortType,
                                               getUser: { viewModel.getUserForUiDisplay(for: $0) },
                                               selectItem: { viewModel.select(item: $0) })
                }
            case .loading:
                CredentialsSkeletonView()
            case let .error(error):
                RetryableErrorView(error: error,
                                   onRetry: { Task { await viewModel.fetchItems() } })
            }

            Spacer()

            CapsuleTextButton(title: #localized("Create login"),
                              titleColor: PassColor.loginInteractionNormMajor2,
                              backgroundColor: PassColor.loginInteractionNormMinor1,
                              height: 52,
                              action: {
                                  if viewModel.shouldAskForUserWhenCreatingNewItem {
                                      viewModel.presentSelectUserActionSheet()
                                  } else {
                                      viewModel.createNewItem(userId: nil)
                                  }
                              })
                              .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.default, value: viewModel.state)
        .animation(.default, value: viewModel.selectedUser)
        .animation(.default, value: viewModel.results)
    }
}

private extension CredentialsView {
    var selectPasskeySheetBinding: Binding<Bool> {
        .init(get: {
            viewModel.selectPasskeySheetInformation != nil
        }, set: { newValue in
            if !newValue {
                viewModel.selectPasskeySheetInformation = nil
            }
        })
    }
}

// MARK: ResultView & elements

private extension CredentialsView {
    var itemList: some View {
        ScrollViewReader { proxy in
            LazyVStack(pinnedViews: .sectionHeaders) {
                // Suggestions section
                let sectionTitle = #localized("Suggestions for %@", viewModel.domain)
                if viewModel.matchedItems.isEmpty {
                    Section(content: {
                        Text("No suggestions")
                            .font(.callout.italic())
                            .padding(.horizontal)
                            .foregroundStyle(PassColor.textWeak)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .plainListRow()
                    }, header: {
                        Text(sectionTitle)
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundStyle(PassColor.textNorm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    })
                } else {
                    section(for: viewModel.matchedItems,
                            headerTitle: sectionTitle,
                            headerColor: PassColor.textNorm,
                            headerFontWeight: .bold)
                }

                // Not matched items sections
                switch viewModel.notMatchedItemSections {
                case .fetching:
                    ProgressView()

                case let .fetched(sections):
                    let itemCount = sections.reduce(0) { $0 + $1.items.count }
                    if itemCount > 0 {
                        HStack {
                            Text("Other items")
                                .font(.callout)
                                .fontWeight(.bold)
                                .adaptiveForegroundStyle(PassColor.textNorm) +
                                Text(verbatim: " (\(itemCount))")
                                .font(.callout)
                                .adaptiveForegroundStyle(PassColor.textWeak)

                            Spacer()

                            SortTypeButton(selectedSortType: $viewModel.selectedSortType)
                                .animationsDisabled()
                        }
                        .plainListRow()
                        .padding([.top, .horizontal])

                        ForEach(sections) { section in
                            self.section(for: section.items,
                                         headerTitle: section.sectionTitle)
                        }
                    }

                case let .error(error):
                    RetryableErrorView(mode: .defaultHorizontal,
                                       error: error,
                                       onRetry: { Task { await viewModel.filterAndSortItemsAsync() } })
                }
            }
            .padding(.top)
            .listStyle(.plain)
            .refreshable { await viewModel.sync(ignoreError: false) }
            .animation(.default, value: viewModel.matchedItems)
            .animation(.default, value: viewModel.notMatchedItemSections)
            .scrollViewEmbeded()
            .overlay {
                if viewModel.selectedSortType.isAlphabetical {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy,
                                           direction: viewModel.selectedSortType.sortDirection)
                    }
                }
            }
        }
    }
}

// MARK: Sections & elements

private extension CredentialsView {
    @ViewBuilder
    func section(for items: [ItemUiModel],
                 headerTitle: String,
                 headerColor: Color = PassColor.textWeak,
                 headerFontWeight: Font.Weight = .regular) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    ItemRow(item: item,
                            mode: viewModel.mode,
                            getUser: { viewModel.getUserForUiDisplay(for: $0) },
                            onSelect: { viewModel.select(item: $0) })
                }
            }, header: {
                Text(headerTitle)
                    .font(.callout)
                    .fontWeight(headerFontWeight)
                    .foregroundStyle(headerColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
            })
        }
    }
}

private struct ItemRow: View {
    let item: ItemUiModel
    let mode: CredentialsMode
    let getUser: (ItemUiModel) -> UserUiModel?
    let onSelect: (any TitledItemIdentifiable) -> Void

    var body: some View {
        let user = getUser(item)
        Group {
            switch mode {
            case .passwords:
                GenericCredentialItemRow(item: .uiModel(item),
                                         user: user,
                                         selectItem: onSelect)

            case .oneTimeCodes:
                if let totpUri = item.totpUri {
                    let title = if let emailWithoutDomain = user?.emailWithoutDomain {
                        item.itemTitle + " • \(emailWithoutDomain)"
                    } else {
                        item.itemTitle
                    }
                    AuthenticatorRow(thumbnailView: {
                                         ItemSquircleThumbnail(data: item.thumbnailData())
                                     },
                                     uri: totpUri,
                                     title: title,
                                     totpManager: SharedServiceContainer.shared.totpManager(),
                                     onCopyTotpToken: { _ in onSelect(item) })
                        .padding(.top, DesignConstant.sectionPadding / 2)
                }
            }
        }
        .plainListRow()
        .padding(.horizontal)
    }
}

struct MainVaultsOnlyBanner: View {
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Text("Your plan only allows to use items from your first 2 vaults for autofill purposes.")
                .adaptiveForegroundStyle(PassColor.textNorm) +
                Text(verbatim: " ") +
                Text("Upgrade now")
                .underline(color: PassColor.interactionNormMajor1)
                .adaptiveForegroundStyle(PassColor.interactionNormMajor1)
        }
        .padding()
        .background(PassColor.interactionNormMinor1)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onTap)
    }
}

// MARK: SkeletonView

struct CredentialsSkeletonView: View {
    var body: some View {
        VStack {
            HStack {
                SkeletonBlock()
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                SkeletonBlock()
                    .frame(width: DesignConstant.searchBarHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(height: DesignConstant.searchBarHeight)
            .padding(.vertical)
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
                .clipShape(Circle())

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

private extension CredentialsMode {
    var emptyMessage: LocalizedStringKey {
        switch self {
        case .passwords:
            "You currently have no login items"
        case .oneTimeCodes:
            "You currently have no login items with 2FA secret key (TOTP)"
        }
    }
}
