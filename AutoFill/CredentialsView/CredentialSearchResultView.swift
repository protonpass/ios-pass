//
// CredentialSearchResultView.swift
// Proton Pass - Created on 06/07/2023.
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
import SwiftUI

struct CredentialSearchResultView: View, Equatable {
    let results: [ItemSearchResult]
    @Binding var selectedSortType: SortType
    let sortAction: () -> Void
    let selectItem: (TitledItemIdentifiable) -> Void

    var body: some View {
        VStack(spacing: 0) {
            headerView
            searchListView
        }
    }

    static func == (lhs: CredentialSearchResultView, rhs: CredentialSearchResultView) -> Bool {
        lhs.results == rhs.results && lhs.selectedSortType == rhs.selectedSortType
    }
}

private extension CredentialSearchResultView {
    var headerView: some View {
        HStack {
            Text("Results")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(Color(uiColor: PassColor.textNorm)) +
                Text(" (\(results.count))")
                .font(.callout)
                .foregroundColor(Color(uiColor: PassColor.textWeak))

            Spacer()

            SortTypeButton(selectedSortType: $selectedSortType,
                           action: sortAction)
        }
        .padding([.bottom, .horizontal])
    }

    var searchListView: some View {
        ScrollViewReader { proxy in
            List {
                sortableSections(for: results)
            }
            .listStyle(.plain)
            .animation(.default, value: results.count)
            .overlay {
                if selectedSortType.isAlphabetical {
                    HStack {
                        Spacer()
                        SectionIndexTitles(proxy: proxy,
                                           direction: selectedSortType.sortDirection ?? .ascending)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func sortableSections(for items: [some CredentialItem]) -> some View {
        switch selectedSortType {
        case .mostRecent:
            sections(for: items.mostRecentSortResult())
        case .alphabeticalAsc:
            sections(for: items.alphabeticalSortResult(direction: .ascending))
        case .alphabeticalDesc:
            sections(for: items.alphabeticalSortResult(direction: .descending))
        case .newestToOldest:
            sections(for: items.monthYearSortResult(direction: .descending))
        case .oldestToNewest:
            sections(for: items.monthYearSortResult(direction: .ascending))
        }
    }

    func sections(for result: MostRecentSortResult<some CredentialItem>) -> some View {
        Group {
            section(for: result.today, headerTitle: "Today".localized)
            section(for: result.yesterday, headerTitle: "Yesterday".localized)
            section(for: result.last7Days, headerTitle: "Last week".localized)
            section(for: result.last14Days, headerTitle: "Last two weeks".localized)
            section(for: result.last30Days, headerTitle: "Last 30 days".localized)
            section(for: result.last60Days, headerTitle: "Last 60 days".localized)
            section(for: result.last90Days, headerTitle: "Last 90 days".localized)
            section(for: result.others, headerTitle: "More than 90 days".localized)
        }
    }

    func sections(for result: AlphabeticalSortResult<some CredentialItem>) -> some View {
        ForEach(result.buckets, id: \.letter) { bucket in
            section(for: bucket.items, headerTitle: bucket.letter.character)
                .id(bucket.letter.character)
        }
    }

    func sections(for result: MonthYearSortResult<some CredentialItem>) -> some View {
        ForEach(result.buckets, id: \.monthYear) { bucket in
            section(for: bucket.items, headerTitle: bucket.monthYear.relativeString)
        }
    }

    @ViewBuilder
    func section(for items: [some CredentialItem],
                 headerTitle: String,
                 headerColor: UIColor = PassColor.textWeak,
                 headerFontWeight: Font.Weight = .regular) -> some View {
        if items.isEmpty {
            EmptyView()
        } else {
            Section(content: {
                ForEach(items) { item in
                    GenericCredentialItemRow(item: item, selectItem: selectItem)
                        .plainListRow()
                        .padding(.horizontal)
                }
            }, header: {
                Text(headerTitle)
                    .font(.callout)
                    .fontWeight(headerFontWeight)
                    .foregroundColor(Color(uiColor: headerColor))
            })
        }
    }
}
