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

import Client
import Core
import DesignSystem
import Entities
import Factory
import ProtonCoreUIFoundations
import SwiftUI

/// Note section of item detail pages
struct NoteDetailSection: View {
    @State private var isShowingFullNote = false
    private let theme = resolve(\SharedToolingContainer.theme)
    let itemContent: ItemContent
    let vault: Vault?

    var body: some View {
        let tintColor = Color(uiColor: itemContent.type.normMajor2Color)
        HStack(spacing: DesignConstant.sectionPadding) {
            ItemDetailSectionIcon(icon: IconProvider.note, color: itemContent.type.normColor)

            VStack(alignment: .leading, spacing: DesignConstant.sectionPadding / 4) {
                Text("Note")
                    .sectionTitleText()

                TextView(.constant(itemContent.note))
                    .autoDetectDataTypes(.all)
                    .foregroundColor(PassColor.textNorm)
                    .isEditable(false)
                    .onTapGesture {
                        // Pure heuristic
                        if itemContent.note.count > 400 {
                            isShowingFullNote.toggle()
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .tint(tintColor)
        .roundedDetailSection()
        .sheet(isPresented: $isShowingFullNote) {
            FullNoteView(itemContent: itemContent, vault: vault, theme: theme)
        }
    }
}

private struct FullNoteView: View {
    @Environment(\.dismiss) private var dismiss
    let itemContent: ItemContent
    let vault: Vault?
    let theme: Theme

    var body: some View {
        let tintColor = Color(uiColor: itemContent.type.normMajor2Color)
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    ItemDetailTitleView(itemContent: itemContent,
                                        vault: vault,
                                        shouldShowVault: true)
                        .padding(.bottom)
                    Text("Note")
                        .sectionTitleText()
                    TextView(.constant(itemContent.note))
                        .autoDetectDataTypes(.all)
                        .foregroundColor(PassColor.textNorm)
                        .isEditable(false)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CircleButton(icon: IconProvider.chevronDown,
                                 iconColor: itemContent.type.normMajor1Color,
                                 backgroundColor: itemContent.type.normMinor2Color,
                                 action: dismiss.callAsFunction)
                }
            }
        }
        .navigationViewStyle(.stack)
        .tint(tintColor)
        .theme(theme)
    }
}
