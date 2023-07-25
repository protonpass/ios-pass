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
import Combine
import Core
import ProtonCore_Login
import SwiftUI

final class CreateEditNoteViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var note = ""

    override var isSaveable: Bool { !title.isEmpty }

    override init(mode: ItemMode,
                  upgradeChecker: UpgradeCheckerProtocol,
                  vaults: [Vault]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)

        Publishers
            .CombineLatest($title, $note)
            .dropFirst(mode.isEditMode ? 1 : 3)
            .sink(receiveValue: { [unowned self] _ in
                didEditSomething = true
            })
            .store(in: &cancellables)
    }

    override func bindValues() {
        if case let .edit(itemContent) = mode,
           case .note = itemContent.contentData {
            title = itemContent.name
            note = itemContent.note
        }
    }

    override func itemContentType() -> ItemContentType { .note }

    override func generateItemContent() -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: note,
                            itemUuid: UUID().uuidString,
                            data: ItemContentData.note,
                            customFields: [])
    }
}
