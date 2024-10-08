//
// ItemDetailView.swift
// Proton Pass - Created on 08/10/2024.
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
import ProtonCoreUIFoundations
import SwiftUI

struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var expandedMoreInfo = false
    let itemContent: ItemContent
    let vault: Vault?
    let onSelect: (String) -> Void

    var body: some View {
        VStack {
            ItemDetailTitleView(itemContent: itemContent,
                                vault: vault,
                                shouldShowVault: true)
                .onTapGesture {
                    onSelect(itemContent.title)
                }

            ItemDetailHistorySection(itemContent: itemContent, action: nil)

            ItemDetailMoreInfoSection(isExpanded: $expandedMoreInfo,
                                      itemContent: itemContent,
                                      vault: vault,
                                      onCopy: nil)
                .padding(.top, 24)
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleButton(icon: IconProvider.chevronDown,
                             iconColor: itemContent.type.normMajor2Color,
                             backgroundColor: itemContent.type.normMinor1Color,
                             accessibilityLabel: "Close",
                             action: dismiss.callAsFunction)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scrollViewEmbeded()
        .background(PassColor.backgroundNorm.toColor)
        .navigationStackEmbeded()
    }
}
