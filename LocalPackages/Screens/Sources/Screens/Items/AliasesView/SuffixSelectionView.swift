//
// SuffixSelectionView.swift
// Proton Pass - Created on 02/08/2024.
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

import Client
import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

public struct SuffixSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: SuffixSelection

    public init(selection: Binding<SuffixSelection>) {
        _selection = selection
    }

    private var tintColor: UIColor { PassColor.aliasInteractionNormMajor2 }

    public var body: some View {
        NavigationStack {
            // ZStack instead of VStack because of SwiftUI bug.
            // See more in "CreateAliasLiteView.swift"
            ZStack(alignment: .bottom) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(selection.suffixes, id: \.suffix) { suffix in
                            HStack {
                                Text(suffix.suffix)
                                    .foregroundStyle((isSelected(suffix) ?
                                            tintColor : PassColor.textNorm).toColor)
                                Spacer()

                                if isSelected(suffix) {
                                    Image(uiImage: IconProvider.checkmark)
                                        .foregroundStyle(tintColor.toColor)
                                }
                            }
                            .contentShape(.rect)
                            .background(Color.clear)
                            .padding(.horizontal)
                            .frame(height: OptionRowHeight.compact.value)
                            .onTapGesture {
                                selection.selectedSuffix = suffix
                                dismiss()
                            }

                            PassDivider()
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(PassColor.backgroundWeak.toColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Suffix")
                        .navigationTitleText()
                }
            }
        }
    }

    private func isSelected(_ suffix: Suffix) -> Bool {
        suffix == selection.selectedSuffix
    }
}
