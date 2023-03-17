//
// SearchRecentResultsView.swift
// Proton Pass - Created on 17/03/2023.
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
import SwiftUI
import UIComponents

struct SearchRecentResultsView: View {
    let results: [SearchEntryUiModel]
    let onSelect: (SearchEntry) -> Void
    let onRemove: (SearchEntry) -> Void
    let onClearResults: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("Recent searches")
                    .font(.callout)
                    .fontWeight(.bold) +
                Text(" (\(results.count))")
                    .font(.callout)
                    .foregroundColor(.textWeak)

                Spacer()

                Button(action: onClearResults) {
                    Text("Clear")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.passBrand)
                }
            }

            List {
                ForEach(results) { result in
                    SearchEntryView(entry: result,
                                    onSelect: { onSelect(result.entry) },
                                    onRemove: { onRemove(result.entry) })
                }
            }
            .listStyle(.plain)
            .animation(.default, value: results)
        }
    }
}

private struct SearchEntryView: View {
    let entry: SearchEntryUiModel
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                HStack {
                    VStack {
                        Text(entry.itemContent.name)
                        Text(entry.itemContent.note)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onRemove) {
                Text("X")
            }
            .buttonStyle(.plain)
        }
    }
}
