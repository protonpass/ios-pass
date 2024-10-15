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
import DesignSystem
import Entities
import Macro
import Screens
import SwiftUI

struct CredentialSearchResultView: View {
    @StateObject private var viewModel: CredentialSearchResultViewModel
    @Binding var selectedSortType: SortType
    let getUser: (any ItemIdentifiable) -> UserUiModel?
    let selectItem: (any TitledItemIdentifiable) -> Void

    init(results: [ItemSearchResult],
         selectedSortType: Binding<SortType>,
         getUser: @escaping (any ItemIdentifiable) -> UserUiModel?,
         selectItem: @escaping (any TitledItemIdentifiable) -> Void) {
        _selectedSortType = selectedSortType
        _viewModel = .init(wrappedValue: .init(results: results))
        self.getUser = getUser
        self.selectItem = selectItem
    }

    var body: some View {
        headerView

        TableView(sections: viewModel.sections,
                  configuration: .init(showSectionIndexTitles: selectedSortType.isAlphabetical),
                  id: nil,
                  itemView: { item in
                      GenericCredentialItemRow(item: item,
                                               user: getUser(item),
                                               selectItem: selectItem)
                  },
                  headerView: { _ in
                      nil
                  })
                  .task {
                      viewModel.filterAndSortItems(selectedSortType)
                  }
    }
}

private extension CredentialSearchResultView {
    var headerView: some View {
        HStack {
            Text("Results")
                .font(.callout)
                .fontWeight(.bold)
                .adaptiveForegroundStyle(PassColor.textNorm.toColor) +
                Text(verbatim: " (\(viewModel.results.count))")
                .font(.callout)
                .adaptiveForegroundStyle(PassColor.textWeak.toColor)

            Spacer()

            SortTypeButton(selectedSortType: $selectedSortType)
        }
        .padding([.bottom, .horizontal])
    }
}

private typealias SearchResultSection = TableView<ItemSearchResult, GenericCredentialItemRow, Text>.Section

@MainActor
private final class CredentialSearchResultViewModel: ObservableObject {
    @Published private(set) var sections: [SearchResultSection] = []

    let results: [ItemSearchResult]

    init(results: [ItemSearchResult]) {
        self.results = results
    }

    func filterAndSortItems(_ sortType: SortType) {
        let type = Int.max
        let sections: [SearchResultSection] = {
            switch sortType {
            case .mostRecent:
                let results = results.mostRecentSortResult()
                return [
                    .init(type: type,
                          title: #localized("Today"),
                          items: results.today),
                    .init(type: type,
                          title: #localized("Yesterday"),
                          items: results.yesterday),
                    .init(type: type,
                          title: #localized("Last week"),
                          items: results.last7Days),
                    .init(type: type,
                          title: #localized("Last two weeks"),
                          items: results.last14Days),
                    .init(type: type,
                          title: #localized("Last 30 days"),
                          items: results.last30Days),
                    .init(type: type,
                          title: #localized("Last 60 days"),
                          items: results.last60Days),
                    .init(type: type,
                          title: #localized("Last 90 days"),
                          items: results.last90Days),
                    .init(type: type,
                          title: #localized("More than 90 days"),
                          items: results.others)
                ]

            case .alphabeticalAsc:
                let results = results.alphabeticalSortResult(direction: .ascending)
                return results.buckets.map { bucket in
                    .init(type: type,
                          title: bucket.letter.character,
                          items: bucket.items)
                }

            case .alphabeticalDesc:
                let results = results.alphabeticalSortResult(direction: .descending)
                return results.buckets.map { bucket in
                    .init(type: type,
                          title: bucket.letter.character,
                          items: bucket.items)
                }

            case .newestToOldest:
                let results = results.monthYearSortResult(direction: .descending)
                return results.buckets.map { bucket in
                    .init(type: type,
                          title: bucket.monthYear.relativeString,
                          items: bucket.items)
                }

            case .oldestToNewest:
                let results = results.monthYearSortResult(direction: .ascending)
                return results.buckets.map { bucket in
                    .init(type: type,
                          title: bucket.monthYear.relativeString,
                          items: bucket.items)
                }
            }
        }()
        self.sections = sections.filter { !$0.items.isEmpty }
    }
}
