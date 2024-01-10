//
// ItemDetailMoreInfoSection.swift
// Proton Pass - Created on 06/02/2023.
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
import Factory
import Foundation
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ItemDetailMoreInfoSection: View {
    private let clipboardManager = resolve(\SharedServiceContainer.clipboardManager)
    @Binding var isExpanded: Bool
    private let item: ItemContent

    init(isExpanded: Binding<Bool>,
         itemContent: ItemContent) {
        _isExpanded = isExpanded
        item = itemContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack {
                    Label(title: {
                        Text("More info")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(uiColor: PassColor.textWeak))
                    }, icon: {
                        icon(from: IconProvider.infoCircle)
                    })

                    Spacer()

                    if isExpanded {
                        icon(from: IconProvider.chevronUp)
                    } else {
                        icon(from: IconProvider.chevronDown)
                    }
                }
            }

            if isExpanded {
                VStack(alignment: .leading) {
                    HStack {
                        title(#localized("Item ID") + ":")
                        Text(item.itemId)
                            .textSelection(.enabled)
                            .onTapGesture(perform: copyItemId)
                        Spacer()
                    }.frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        title(#localized("Vault ID") + ":")
                        Text(item.shareId)
                            .textSelection(.enabled)
                            .onTapGesture(perform: copyVaultId)
                        Spacer()
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption)
                .foregroundColor(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { isExpanded.toggle() }
        .animation(.default, value: isExpanded)
    }
}

private extension ItemDetailMoreInfoSection {
    func copyItemId() {
        clipboardManager.copy(text: item.itemId,
                              bannerMessage: #localized("Item ID copied"))
    }

    func copyVaultId() {
        clipboardManager.copy(text: item.shareId,
                              bannerMessage: #localized("Vault ID copied"))
    }

    func icon(from image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 16)
            .foregroundColor(PassColor.textWeak.toColor)
    }

    func title(_ text: String) -> some View {
        Text(text)
            .fontWeight(.semibold)
            .frame(maxHeight: .infinity, alignment: .topTrailing)
    }
}
