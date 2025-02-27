//
// CreateEditCustomItemViewModel.swift
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

import Client
import Core
import Entities
import Foundation

final class CreateEditCustomItemViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var title = ""

    override var isSaveable: Bool {
        super.isSaveable && !title.isEmpty
    }

    override func bindValues() {
        switch mode {
        case let .create(_, type):
            if case let .custom(template) = type {
                assert(template != .sshKey && template != .wifi,
                       "SSH key and Wifi are not supported as custom item")
            }

        case let .clone(itemContent), let .edit(itemContent):
            if case let .custom(data) = itemContent.contentData {
                title = itemContent.name
            }
        }
    }

    override var itemContentType: ItemContentType { .custom }

    override func generateItemContent() async -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: "",
                            itemUuid: UUID().uuidString,
                            data: ItemContentData.custom(.init(sections: [])),
                            customFields: [])
    }
}
