//
// CreateEditSshKeyViewModel.swift
// Proton Pass - Created on 27/02/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Core
import Entities
import Foundation

final class CreateEditSshKeyViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var publicKey = ""
    @Published var privateKey = ""

    override var isSaveable: Bool {
        super.isSaveable && !title.isEmpty
    }

    override var shouldUpgrade: Bool {
        if case .create = mode, isFreeUser {
            return true
        }
        return false
    }

    override func bindValues() {
        switch mode {
        case let .clone(itemContent), let .edit(itemContent):
            if case let .sshKey(data) = itemContent.contentData {
                title = itemContent.name
                publicKey = data.publicKey
                privateKey = data.privateKey
            }

        default:
            break
        }
    }

    override var itemContentType: ItemContentType { .sshKey }

    override func generateItemContent() async -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: "",
                            itemUuid: UUID().uuidString,
                            data: ItemContentData.sshKey(.init(privateKey: privateKey,
                                                               publicKey: publicKey,
                                                               extraSections: customSections)),
                            customFields: customFields)
    }
}
