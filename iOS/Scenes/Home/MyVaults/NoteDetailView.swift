//
// NoteDetailView.swift
// Proton Pass - Created on 07/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

struct NoteDetailView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: NoteDetailViewModel
    @State private var isShowingTrashingAlert = false

    init(viewModel: NoteDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Note")
            Text(viewModel.note)
                .font(.callout)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .padding(.top)
        .moveToTrashAlert(isPresented: $isShowingTrashingAlert, onTrash: viewModel.trashAction)
        .toolbar(content: toolbarContent)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(uiImage: IconProvider.chevronLeft)
                    .foregroundColor(.primary)
            })
        }

        ToolbarItem(placement: .principal) {
            Text(viewModel.name)
                .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            trailingMenu
        }
    }

    private var trailingMenu: some View {
        Menu(content: {
            Button(action: {
                print("Edit")
            }, label: {
                Label(title: {
                    Text("Edit note")
                }, icon: {
                    Image(uiImage: IconProvider.eraser)
                })
            })

            Divider()

            DestructiveButton(title: "Move to trash",
                              icon: IconProvider.trash,
                              action: {
                isShowingTrashingAlert.toggle()
            })
        }, label: {
            Image(uiImage: IconProvider.threeDotsHorizontal)
                .foregroundColor(.primary)
        })
    }
}
