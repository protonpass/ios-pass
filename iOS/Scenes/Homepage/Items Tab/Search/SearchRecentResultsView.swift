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
import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

struct SearchRecentResultsView: View {
    let results: [SearchEntryUiModel]
    let onSelect: (SearchEntryUiModel) -> Void
    let onRemove: (SearchEntryUiModel) -> Void
    let onClearResults: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("Recent searches")
                    .font(.callout)
                    .fontWeight(.bold)
                    .adaptiveForegroundStyle(PassColor.textNorm) +
                    Text(verbatim: " (\(results.count))")
                    .font(.callout)
                    .adaptiveForegroundStyle(PassColor.textWeak)

                Spacer()

                Button(action: onClearResults) {
                    Text("Clear")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(PassColor.textWeak)
                        .underline(color: PassColor.textWeak)
                }
            }
            .padding(.horizontal)

            List {
                ForEach(results) { result in
                    SearchEntryView(uiModel: result,
                                    onSelect: { onSelect(result) },
                                    onRemove: { onRemove(result) })
                        .plainListRow()
                        .padding(.horizontal)
                }
            }
            .listStyle(.plain)
            .animation(.default, value: results)
        }
    }
}

private struct SearchEntryView: View {
    let uiModel: SearchEntryUiModel
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Button(action: onSelect) {
                GeneralItemRow(thumbnailView: { ItemSquircleThumbnail(data: uiModel.thumbnailData()) },
                               title: uiModel.title,
                               description: uiModel.description)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onRemove) {
                ZStack {
                    IconProvider.cross
                        .resizable()
                        .scaledToFill()
                        .foregroundStyle(PassColor.textWeak)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 48, height: 48)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 64)
    }
}
