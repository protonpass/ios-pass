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
    @StateObject private var viewModel: NoteDetailViewModel
    @Namespace private var bottomID
    private let tintColor = UIColor.systemYellow

    init(viewModel: NoteDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                VStack(spacing: 24) {
                    Text(viewModel.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if viewModel.note.isEmpty {
                        Text("Empty note")
                            .placeholderText()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(viewModel.note)
                            .sectionContentText()
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ItemDetailMoreInfoSection(
                        itemContent: viewModel.itemContent,
                        onExpand: { withAnimation { value.scrollTo(bottomID, anchor: .bottom) } })
                    .padding(.top, 24)
                    .id(bottomID)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.passBackground)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar {
            ItemDetailToolbar(itemContent: viewModel.itemContent,
                              onGoBack: viewModel.goBack,
                              onEdit: viewModel.edit,
                              onRevealMoreOptions: {})
        }
    }
}
