//
// CreateEditItemTitleSection.swift
// Proton Pass - Created on 13/02/2023.
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

struct CreateEditItemTitleSection<Field: Hashable>: View {
    @Binding var title: String
    let focusedField: FocusState<Field?>.Binding
    let field: Field
    let selectedVault: Vault
    let itemContentType: ItemContentType
    let isEditMode: Bool
    var onChangeVault: () -> Void
    var onSubmit: (() -> Void)?

    var body: some View {
        switch itemContentType {
        case .note:
            if isEditMode {
                EmptyView()
            } else {
                vaultRow
                    .roundedEditableSection()
            }

        default:
            if isEditMode {
                titleRow
                    .roundedEditableSection()
            } else {
                VStack(spacing: 0) {
                    vaultRow
                    PassSectionDivider()
                    titleRow
                }
                .roundedEditableSection()
            }
        }
    }

    private var vaultRow: some View {
        Button(action: onChangeVault) {
            HStack {
                VaultThumbnail(vault: selectedVault)
                VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                    Text("Vault")
                        .sectionTitleText()
                    Text(selectedVault.name)
                        .foregroundColor(Color(uiColor: PassColor.textNorm))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ItemDetailSectionIcon(icon: IconProvider.chevronDown)
            }
            .padding(DesignConstant.sectionPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var titleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Title")
                    .sectionTitleText()
                TextEditorWithPlaceholder(text: $title,
                                          focusedField: focusedField,
                                          field: field,
                                          placeholder: #localized("Untitled"),
                                          font: .title,
                                          fontWeight: .bold,
                                          onSubmit: onSubmit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !title.isEmpty {
                Button(action: {
                    title = ""
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross)
                })
            }
        }
        .padding(DesignConstant.sectionPadding)
        .animation(.default, value: title.isEmpty)
    }
}
