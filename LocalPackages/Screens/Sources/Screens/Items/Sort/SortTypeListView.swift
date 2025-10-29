//
// SortTypeListView.swift
// Proton Pass - Created on 09/03/2023.
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
import SwiftUI

struct SortTypeListView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSortType: SortType

    init(selectedSortType: Binding<SortType>) {
        _selectedSortType = selectedSortType
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 0) {
                ForEach(SortType.allCases, id: \.self) { type in
                    SelectableOptionRow(action: {
                                            selectedSortType = type
                                            dismiss()
                                        },
                                        height: .compact,
                                        content: {
                                            Text(type.title)
                                                .foregroundStyle(type == selectedSortType ?
                                                    PassColor.interactionNormMajor2 : PassColor
                                                    .textNorm)
                                        },
                                        isSelected: type == selectedSortType)

                    PassDivider()
                }
                .padding(.horizontal)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .background(PassColor.backgroundWeak)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sort By", bundle: .module)
                        .navigationTitleText()
                }
            }
        }
    }
}
