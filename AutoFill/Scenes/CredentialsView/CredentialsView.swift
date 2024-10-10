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
import Core
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
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            stateViews
        }
        .task {
            await viewModel.fetchItems()
            await viewModel.sync(ignoreError: true)
        }
        .localAuthentication(onSuccess: { _ in viewModel.handleAuthenticationSuccess() },
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
                       // swiftlint:disable:next line_length
                       Text("Would you want to associate « \(information.url) » with « \(information.item.itemTitle) »?")
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
                       viewModel.notMatchedItems.isEmpty {
                        VStack {
                            Spacer()
                            Text(viewModel.mode.emptyMessage)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(PassColor.textNorm.toColor)
                                .padding()
                            Spacer()
                        }
                    } else {
                        itemList(matchedItems: viewModel.matchedItems,
                                 notMatchedItems: viewModel.notMatchedItems)
                    }
                }
            case .searching:
                ProgressView()
            case let .searchResults(results):
                if results.isEmpty {
                    NoSearchResultsInAllVaultView(query: viewModel.query)
                } else {
                    CredentialSearchResultView(results: results,
                                               getUser: { viewModel.getUserForUiDisplay(for: $0) },
                                               selectedSortType: $viewModel.selectedSortType,
                                               sortAction: { viewModel.presentSortTypeList() },
                                               selectItem: { viewModel.select(item: $0) })
                }
            case .loading:
                CredentialsSkeletonView()
            case let .error(error):
                RetryableErrorView(errorMessage: error.localizedDescription,
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
                              .padding(.vertical, 8)
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
    func itemList(matchedItems: [ItemUiModel],
                  notMatchedItems: [ItemUiModel]) -> some View {
        ScrollViewReader { proxy in
            Group {
                // swiftlint:disable:next todo
                // TODO: Remove later on after using the same UI component to render item list
                let isListMode = matchedItems.count + notMatchedItems.count <= 200
                if isListMode {
                    List {
                        matchedItemsSection(matchedItems, isListMode: isListMode)
                        notMatchedItemsSection(notMatchedItems, isListMode: isListMode)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            matchedItemsSection(matchedItems, isListMode: isListMode)
                            notMatchedItemsSection(notMatchedItems, isListMode: isListMode)
                        }
                    }
                }
            }
            .padding(.top)
            .listStyle(.plain)
            .refreshable { await viewModel.sync(ignoreError: false) }
            .animation(.default, value: matchedItems.hashValue)
            .animation(.default, value: notMatchedItems.hashValue)
            .overlay {
                if viewModel.selectedSortType.isAlphabetical {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy,
                                           direction: viewModel.selectedSortType.sortDirection ?? .ascending)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func matchedItemsSection(_ items: [ItemUiModel], isListMode: Bool) -> some View {
        let sectionTitle = #localized("Suggestions for %@", viewModel.domain)
        if items.isEmpty {
            Section(content: {
                Text("No suggestions")
                    .font(.callout.italic())
                    .padding(.horizontal)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .plainListRow()
            }, header: {
                Text(sectionTitle)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm.toColor)
            })
        } else {
            section(for: items,
                    isListMode: isListMode,
                    headerTitle: sectionTitle,
                    headerColor: PassColor.textNorm,
                    headerFontWeight: .bold)
        }
    }

    @ViewBuilder
    func notMatchedItemsSection(_ items: [ItemUiModel], isListMode: Bool) -> some View {
        if !items.isEmpty {
            HStack {
                Text("Other items")
                    .font(.callout)
                    .fontWeight(.bold)
                    .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                    Text(verbatim: " (\(items.count))")
                    .font(.callout)
                    .adaptiveForegroundStyle(PassColor.textWeak.toColor)

                Spacer()

                SortTypeButton(selectedSortType: $viewModel.selectedSortType,
                               action: { viewModel.presentSortTypeList() })
            }
            .plainListRow()
            .padding([.top, .horizontal])
            sortableSections(for: items, isListMode: isListMode)
        }
    }

    var mainVaultsOnlyMessage: some View {
        ZStack {
            Text("Your plan only allows to use items from your first 2 vaults for autofill purposes.")
                .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                Text(verbatim: " ") +
                Text("Upgrade now")
                .underline(color: PassColor.interactionNormMajor1.toColor)
                .adaptiveForegroundStyle(PassColor.interactionNormMajor1.toColor)
        }
        .padding()
        .background(PassColor.interactionNormMinor1.toColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: viewModel.upgrade)
    }
}

// MARK: Sections & elements

private extension CredentialsView {
    @ViewBuilder
    func section(for items: [some CredentialItem],
                 isListMode: Bool,
                 headerTitle: String,
                 headerColor: UIColor = PassColor.textWeak,
                 headerFontWeight: Font.Weight = .regular) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    let user = viewModel.getUserForUiDisplay(for: item)
                    Group {
                        switch viewModel.mode {
                        case .passwords:
                            GenericCredentialItemRow(item: item,
                                                     user: user,
                                                     selectItem: { viewModel.select(item: $0) })

                        case .oneTimeCodes:
                            if let item = item as? ItemUiModel,
                               let totpUri = item.totpUri {
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
                                                 onCopyTotpToken: { _ in viewModel.select(item: item) })
                                    .padding(.top, DesignConstant.sectionPadding / 2)
                            }
                        }
                    }
                    .plainListRow()
                    .padding(.horizontal)
                }
            }, header: {
                Text(headerTitle)
                    .font(.callout)
                    .fontWeight(headerFontWeight)
                    .foregroundStyle(headerColor.toColor)
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
    func sortableSections(for items: [some CredentialItem], isListMode: Bool) -> some View {
        switch viewModel.selectedSortType {
        case .mostRecent:
            sections(for: items.mostRecentSortResult(), isListMode: isListMode)
        case .alphabeticalAsc:
            sections(for: items.alphabeticalSortResult(direction: .ascending), isListMode: isListMode)
        case .alphabeticalDesc:
            sections(for: items.alphabeticalSortResult(direction: .descending), isListMode: isListMode)
        case .newestToOldest:
            sections(for: items.monthYearSortResult(direction: .descending), isListMode: isListMode)
        case .oldestToNewest:
            sections(for: items.monthYearSortResult(direction: .ascending), isListMode: isListMode)
        }
    }

    func sections(for result: MostRecentSortResult<some CredentialItem>, isListMode: Bool) -> some View {
        Group {
            section(for: result.today,
                    isListMode: isListMode,
                    headerTitle: #localized("Today"))
            section(for: result.yesterday,
                    isListMode: isListMode,
                    headerTitle: #localized("Yesterday"))
            section(for: result.last7Days,
                    isListMode: isListMode,
                    headerTitle: #localized("Last week"))
            section(for: result.last14Days,
                    isListMode: isListMode,
                    headerTitle: #localized("Last two weeks"))
            section(for: result.last30Days,
                    isListMode: isListMode,
                    headerTitle: #localized("Last 30 days"))
            section(for: result.last60Days,
                    isListMode: isListMode,
                    headerTitle: #localized("Last 60 days"))
            section(for: result.last90Days,
                    isListMode: isListMode,
                    headerTitle: #localized("Last 90 days"))
            section(for: result.others,
                    isListMode: isListMode,
                    headerTitle: #localized("More than 90 days"))
        }
    }

    func sections(for result: AlphabeticalSortResult<some CredentialItem>,
                  isListMode: Bool) -> some View {
        ForEach(result.buckets, id: \.letter) { bucket in
            section(for: bucket.items, isListMode: isListMode, headerTitle: bucket.letter.character)
                .id(bucket.letter.character)
        }
    }

    func sections(for result: MonthYearSortResult<some CredentialItem>,
                  isListMode: Bool) -> some View {
        ForEach(result.buckets, id: \.monthYear) { bucket in
            section(for: bucket.items,
                    isListMode: isListMode,
                    headerTitle: bucket.monthYear.relativeString)
        }
    }
}

struct MainVaultsOnlyBanner: View {
    let onTap: () -> Void

    var body: some View {
        ZStack {
            Text("Your plan only allows to use items from your first 2 vaults for autofill purposes.")
                .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                Text(verbatim: " ") +
                Text("Upgrade now")
                .underline(color: PassColor.interactionNormMajor1.toColor)
                .adaptiveForegroundStyle(PassColor.interactionNormMajor1.toColor)
        }
        .padding()
        .background(PassColor.interactionNormMinor1.toColor)
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
