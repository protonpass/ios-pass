//
// NoteDetailSection.swift
// Proton Pass - Created on 03/02/2023.
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
import ProtonCoreUIFoundations
import Screens
import SwiftUI

/// Note section of item detail pages
struct NoteDetailSection: View {
    @State private var isShowingFullNote = false
    let itemContent: ItemContent
    let vault: Share?
    let title: LocalizedStringKey
    let note: String

    init(itemContent: ItemContent, vault: Share?, title: LocalizedStringKey = "Note", note: String? = nil) {
        self.itemContent = itemContent
        self.vault = vault
        self.title = title
        self.note = note ?? itemContent.note
    }

    var body: some View {
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.note, color: itemContent.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text(title)
                    .sectionTitleText()

                TextView(.constant(note))
                    .autoDetectDataTypes(.all)
                    // swiftlint:disable:next deprecated_foregroundcolor_modifier
                    .foregroundColor(PassColor.textNorm)
                    .isEditable(false)
                    .frame(maxHeight: .infinity)
                    .onTapGesture {
                        // Pure heuristic
                        if note.count > 400 {
                            isShowingFullNote.toggle()
                        }
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .tint(itemContent.type.normMajor2Color.toColor)
        .roundedDetailSection()
        .sheet(isPresented: $isShowingFullNote) {
            FullNoteView(itemContent: itemContent, vault: vault, title: title, note: note)
        }
    }
}

private struct FullNoteView: View {
    @Environment(\.dismiss) private var dismiss
    let itemContent: ItemContent
    let vault: Share?
    let title: LocalizedStringKey
    let note: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ItemDetailTitleView(itemContent: itemContent,
                                        vault: vault)
                        .padding(.bottom)
                    Text(title)
                        .sectionTitleText()
                    TextView(.constant(note))
                        .autoDetectDataTypes(.all)
                        // swiftlint:disable:next deprecated_foregroundcolor_modifier
                        .foregroundColor(PassColor.textNorm)
                        .isEditable(false)
                }
                .padding()
            }
            .fullSheetBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CircleButton(icon: IconProvider.chevronDown,
                                 iconColor: itemContent.type.normMajor1Color,
                                 backgroundColor: itemContent.type.normMinor2Color,
                                 accessibilityLabel: "Close",
                                 action: dismiss.callAsFunction)
                }
            }
        }
        .tint(itemContent.type.normMajor2Color.toColor)
    }
}
