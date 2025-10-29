//
// EditSpotlightSearchableContentView.swift
// Proton Pass - Created on 30/01/2024.
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
import SwiftUI

struct EditSpotlightSearchableContentView: View {
    @Environment(\.dismiss) private var dismiss
    let selection: SpotlightSearchableContent
    let onSelect: (SpotlightSearchableContent) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(SpotlightSearchableContent.allCases, id: \.rawValue) { content in
                row(for: content)
                PassDivider()
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Searchable content")
                    .navigationTitleText()
            }
        }
        .scrollViewEmbeded(maxWidth: .infinity)
        .background(PassColor.backgroundWeak)
        .navigationStackEmbeded()
    }
}

private extension EditSpotlightSearchableContentView {
    func row(for content: SpotlightSearchableContent) -> some View {
        SelectableOptionRow(action: { onSelect(content); dismiss() },
                            height: .compact,
                            content: {
                                Text(content.title)
                                    .foregroundStyle(PassColor.textNorm)
                            },
                            isSelected: content == selection)
    }
}
