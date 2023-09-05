//
// ItemTypeFilterOptionsView.swift
// Proton Pass - Created on 01/08/2023.
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

import DesignSystem
import Factory
import SwiftUI

struct ItemTypeFilterOptionsView: View {
    static let rowHeight = OptionRowHeight.compact.value
    @Environment(\.dismiss) private var dismiss
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let theme = resolve(\SharedToolingContainer.theme)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(ItemTypeFilterOption.allCases, id: \.self) { option in
                    row(for: option)
                    PassDivider()
                }
            }
            .padding()
        }
        .navigationTitle("Filter by")
        .navigationBarTitleDisplayMode(.inline)
        .background(PassColor.backgroundNorm.toColor)
        .theme(theme)
        .navigationModifier()
    }
}

private extension ItemTypeFilterOptionsView {
    @ViewBuilder
    func row(for option: ItemTypeFilterOption) -> some View {
        let uiModel = option.uiModel(from: vaultsManager.itemCount)
        let isSelected = option == vaultsManager.filterOption
        Button(action: {
            vaultsManager.updateItemTypeFilterOption(option)
            dismiss()
        }, label: {
            HStack {
                Label(title: {
                    Text("\(uiModel.title) (\(uiModel.count))")
                        .foregroundColor(Color(uiColor: isSelected ?
                                PassColor.interactionNormMajor2 : PassColor.textNorm))
                }, icon: {
                    Image(uiImage: uiModel.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 18)
                        .foregroundColor(Color(uiColor: isSelected ?
                                PassColor.interactionNormMajor2 : PassColor.textWeak))
                })

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(PassColor.interactionNormMajor2.toColor)
                }
            }
            .contentShape(Rectangle())
            .frame(height: Self.rowHeight)
        })
        // swiftformat:disable:next isEmpty
        .opacityReduced(uiModel.count == 0) // swiftlint:disable:this empty_count
    }
}
