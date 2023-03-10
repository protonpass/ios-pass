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

private let kTopBarHeight: CGFloat = 48

struct ItemsTabView: View {
    @StateObject var viewModel: ItemsTabViewModel
    @State private var safeAreaInsets = EdgeInsets.zero

    var body: some View {
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

                            Button(action: viewModel.presentSortTypeList) {
                                Label(viewModel.selectedSortType.title, systemImage: "arrow.up.arrow.down")
                                    .font(.callout.weight(.medium))
                                    .foregroundColor(.passBrand)
                            }
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

    private func itemList(_ result: MostRecentSortResult<ItemListUiModelV2>) -> some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                section(for: result.today, headerTitle: "Today")
                section(for: result.yesterday, headerTitle: "Yesterday")
                section(for: result.last7Days, headerTitle: "Last week")
                section(for: result.last14Days, headerTitle: "Last two weeks")
                section(for: result.last30Days, headerTitle: "Last 30 days")
                section(for: result.last60Days, headerTitle: "Last 60 days")
                section(for: result.last90Days, headerTitle: "Last 90 days")
                section(for: result.others, headerTitle: "More than 90 days")
            }
            .padding(.horizontal)
            .padding(.bottom, safeAreaInsets.bottom)
        }
    }

    @ViewBuilder
    private func section(for items: [ItemListUiModelV2], headerTitle: String) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    GeneralItemRow(thumbnailView: { thumbnail(for: item) },
                                   title: item.title,
                                   description: item.description,
                                   action: { viewModel.viewDetail(of: item) })
                }
            }, header: {
                sectionHeader(headerTitle)
            })
        }
    }

    private func itemList(_ result: AlphabeticalSortResult<ItemListUiModelV2>) -> some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(result.buckets, id: \.letter) { bucket in
                    section(for: bucket)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, safeAreaInsets.bottom)
        }
    }

    @ViewBuilder
    private func section(for bucket: AlphabetBucket<ItemListUiModelV2>) -> some View {
        Section(content: {
            ForEach(bucket.items) { item in
                GeneralItemRow(thumbnailView: { thumbnail(for: item) },
                               title: item.title,
                               description: item.description,
                               action: { viewModel.viewDetail(of: item) })
            }
        }, header: {
            sectionHeader(bucket.letter.character)
        })
    }

    private func itemList(_ result: MonthYearSortResult<ItemListUiModelV2>) -> some View {
        ScrollView {
            LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                ForEach(result.buckets, id: \.monthYear) { bucket in
                    section(for: bucket)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, safeAreaInsets.bottom)
        }
    }

    @ViewBuilder
    private func section(for bucket: MonthYearBucket<ItemListUiModelV2>) -> some View {
        Section(content: {
            ForEach(bucket.items) { item in
                GeneralItemRow(thumbnailView: { thumbnail(for: item) },
                               title: item.title,
                               description: item.description,
                               action: { viewModel.viewDetail(of: item) })
            }
        }, header: {
            sectionHeader(bucket.monthYear.relativeString)
        })
    }

    @ViewBuilder
    private func thumbnail(for item: ItemListUiModelV2) -> some View {
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
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.textWeak)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.passBackground)
    }
}
