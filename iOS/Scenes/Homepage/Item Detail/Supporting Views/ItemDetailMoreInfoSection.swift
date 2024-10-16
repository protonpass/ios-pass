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

import DesignSystem
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct ItemDetailMoreInfoSection: View {
    @Binding var isExpanded: Bool
    private let item: ItemContent
    private let vault: Vault?
    let onCopy: ((_ text: String, _ bannerMessage: String) -> Void)?

    init(isExpanded: Binding<Bool>,
         itemContent: ItemContent,
         vault: Vault?,
         onCopy: ((_ text: String, _ bannerMessage: String) -> Void)?) {
        _isExpanded = isExpanded
        item = itemContent
        self.vault = vault
        self.onCopy = onCopy
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack {
                    Label(title: {
                        Text("More info")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(PassColor.textWeak.toColor)
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
                    infoRow(title: #localized("Item ID"),
                            value: item.itemId,
                            copyMessage: #localized("Item ID copied"))

                    if let vault {
                        infoRow(title: #localized("Vault ID"),
                                value: vault.id,
                                copyMessage: #localized("Vault ID copied"))
                    }

                    if Bundle.main.isQaBuild {
                        infoRow(title: "Share ID",
                                value: item.shareId,
                                copyMessage: "Share ID copied")

                        infoRow(title: "CVF", value: "\(item.item.contentFormatVersion)")
                    }
                }
                .font(.caption)
                .foregroundStyle(PassColor.textWeak.toColor)
                .frame(maxWidth: .infinity)
            }
        }
        .contentShape(.rect)
        .onTapGesture { isExpanded.toggle() }
        .animation(.default, value: isExpanded)
    }
}

private extension ItemDetailMoreInfoSection {
    func infoRow(title: String, value: String, copyMessage: String? = nil) -> some View {
        HStack {
            Text(verbatim: "\(title) :")
                .fontWeight(.semibold)
                .frame(maxHeight: .infinity, alignment: .topTrailing)

            Text(value)
                .if(copyMessage) { view, copyMessage in
                    view.textSelection(.enabled)
                        .onTapGesture {
                            if let onCopy {
                                onCopy(value, copyMessage)
                            }
                        }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func icon(from image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 16)
            .foregroundStyle(PassColor.textWeak.toColor)
    }
}
