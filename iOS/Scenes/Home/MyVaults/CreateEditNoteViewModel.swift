//
// CreateEditNoteViewModel.swift
// Proton Pass - Created on 25/07/2022.
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

import Client
import Core
import ProtonCore_Login
import SwiftUI

final class CreateEditNoteViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var name = ""
    @Published var note = ""

    var isEmpty: Bool { name.isEmpty && note.isEmpty }
    override var isSaveable: Bool { !name.isEmpty }

    override func bindValues() {
        if case let .edit(itemContent) = mode,
           case .note = itemContent.contentData {
            self.name = itemContent.name
            self.note = itemContent.note
        }
    }

    override func navigationBarTitle() -> String {
        switch mode {
        case .create:
            return "Create new note"
        case .edit:
            return "Edit note"
        }
    }

    override func itemContentType() -> ItemContentType { .note }

    override func generateItemContent() -> ItemContentProtobuf {
        ItemContentProtobuf(name: name,
                            note: note,
                            data: ItemContentData.note)
    }
}
