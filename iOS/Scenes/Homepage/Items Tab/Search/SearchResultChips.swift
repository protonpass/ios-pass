//
// SearchResultChips.swift
// Proton Pass - Created on 15/03/2023.
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
import ProtonCoreUIFoundations
import SwiftUI

struct SearchResultChips: View {
    @Binding var selectedType: ItemContentType?
    let itemCount: ItemCount

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ItemCountChip(icon: nil,
                              title: #localized("All"),
                              count: itemCount.total,
                              isSelected: selectedType == nil,
                              action: { selectedType = nil })

                chip(for: .login, numberOfEntries: itemCount.login)
                chip(for: .alias, numberOfEntries: itemCount.alias)
                chip(for: .creditCard, numberOfEntries: itemCount.creditCard)
                chip(for: .note, numberOfEntries: itemCount.note)
                chip(for: .identity, numberOfEntries: itemCount.identity)
                chip(for: .custom, numberOfEntries: itemCount.custom)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func chip(for type: ItemContentType, numberOfEntries: Int) -> some View {
        if numberOfEntries > 0 {
            ItemCountChip(icon: type.regularIcon,
                          title: type.chipTitle,
                          count: numberOfEntries,
                          isSelected: selectedType == type,
                          action: { selectedType = type })
        }
    }
}

private struct ItemCountChip: View {
    let icon: UIImage?
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 6) {
                if let icon {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(isSelected ? PassColor.textInvert : PassColor.interactionNormMajor2)
                        .frame(width: 16, height: 16)
                }

                Text(title)
                    .foregroundStyle(isSelected ? PassColor.textInvert : PassColor.textNorm)

                Text(verbatim: "(\(count))")
                    .foregroundStyle(isSelected ? PassColor.textInvert : PassColor.textNorm)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ?
                PassColor.interactionNormMajor1 : .clear)
            .clipShape(Capsule())
            .overlay(Capsule()
                .stroke(PassColor.interactionNormMinor1, lineWidth: 1))
            .animation(.default, value: isSelected)
        }
        .buttonStyle(.plain)
        .animationsDisabled()
    }
}
