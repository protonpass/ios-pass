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
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct SearchResultChips: View {
    @Binding var selectedType: ItemContentType?
    let itemCount: ItemCount

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ItemCountChip(icon: IconProvider.listBullets,
                              title: "All",
                              count: itemCount.total,
                              isSelected: selectedType == nil,
                              action: { selectedType = nil })

                chip(for: .login, count: itemCount.loginCount)
                chip(for: .alias, count: itemCount.aliasCount)
                chip(for: .note, count: itemCount.noteCount)
            }
            .padding(.horizontal)
        }
    }

    private func chip(for type: ItemContentType, count: Int) -> some View {
        ItemCountChip(icon: type.icon,
                      title: type.chipTitle,
                      count: count,
                      isSelected: selectedType == type,
                      action: { selectedType = type })
    }
}

private struct ItemCountChip: View {
    let icon: UIImage
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 6) {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color(uiColor: isSelected ? PassColor.textNorm : PassColor.textWeak))
                    .frame(width: 16, height: 16)

                HStack(spacing: 4) {
                    Text(title)
                        .foregroundColor(Color(uiColor: PassColor.textNorm))

                    VStack {
                        Text(" \(count)")
                            .font(.caption)
                            .foregroundColor(Color(uiColor: PassColor.textNorm))
                            .padding(.top, 4)
                        Spacer()
                    }
                    .fixedSize(horizontal: true, vertical: true)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(uiColor: isSelected ?
                              PassColor.interactionNormMajor1 : PassColor.textDisabled))
            .clipShape(Capsule())
            .animation(.default, value: isSelected)
        }
        .buttonStyle(.plain)
        .disabled(count == 0) // swiftlint:disable:this empty_count
        .animationsDisabled()
    }
}

extension ItemContentType {
    var chipTitle: String {
        switch self {
        case .login:
            return "Login"
        case .alias:
            return "Alias"
        case .note:
            return "Note"
        }
    }
}
