//
// NoteEditSection.swift
// Proton Pass - Created on 10/02/2023.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct NoteEditSection: View {
    @FocusState private var isFocused: Bool
    @State private var isShowingTextEditor: Bool
    @Binding var note: String

    init(note: Binding<String>) {
        _note = note
        _isShowingTextEditor = .init(initialValue: !note.wrappedValue.isEmpty)
    }

    var body: some View {
        HStack {
            ItemDetailSectionIcon(icon: IconProvider.note,
                                  color: .textWeak)

            VStack(alignment: .leading, spacing: kItemDetailSectionPadding / 4) {
                Text("Note")
                    .sectionTitleText()

                if isShowingTextEditor {
                    ZStack(alignment: .topLeading) {
                        // Hacky way to make TextEditor grows in height gradually
                        Text(note)
                            .hidden()
                        if #available(iOS 16.0, *) {
                            TextEditor(text: $note)
                                .focused($isFocused)
                                .scrollContentBackground(.hidden)
                        } else {
                            TextEditor(text: $note)
                                .focused($isFocused)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: 350, alignment: .topLeading)
                } else {
                    Button(action: {
                        isShowingTextEditor.toggle()
                        isFocused = true
                    }, label: {
                        Label("Add", systemImage: "plus")
                    })
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isShowingTextEditor {
                Button(action: {
                    note = ""
                    isShowingTextEditor.toggle()
                }, label: {
                    ItemDetailSectionIcon(icon: IconProvider.cross,
                                          color: .textWeak)
                })
            }
        }
        .padding(kItemDetailSectionPadding)
        .roundedEditableSection()
        .animation(.default, value: isShowingTextEditor)
    }
}
