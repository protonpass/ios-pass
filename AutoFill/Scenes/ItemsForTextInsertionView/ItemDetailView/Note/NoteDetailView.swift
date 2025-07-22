//
// NoteDetailView.swift
// Proton Pass - Created on 09/10/2024.
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
import SwiftUI

struct NoteDetailView: View {
    @StateObject private var viewModel: BaseItemDetailViewModel

    init(_ viewModel: BaseItemDetailViewModel) {
        _viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        if viewModel.item.content.note.isEmpty {
            Text("Empty note")
                .placeholderText()
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            ReadOnlyTextView(viewModel.item.content.note)
        }

        CustomFieldSections(itemContentType: viewModel.item.content.type,
                            fields: viewModel.item.content.customFields,
                            isFreeUser: viewModel.isFreeUser,
                            onSelectHiddenText: viewModel.autofill,
                            onSelectTotpToken: viewModel.autofill,
                            onUpgrade: viewModel.upgrade)
    }
}
