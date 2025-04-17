//
// CreateEditWifiViewModel.swift
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

final class CreateEditWifiViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var ssid = ""
    @Published var password = ""
    @Published var security: WifiData.Security = .unspecified

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
            if case let .wifi(data) = itemContent.contentData {
                title = itemContent.name
                ssid = data.ssid
                password = data.password
                security = data.security
                customSections = data.extraSections
            }

        default:
            break
        }
    }

    override var itemContentType: ItemContentType { .wifi }

    override func generateItemContent() async -> ItemContentProtobuf {
        ItemContentProtobuf(name: title,
                            note: "",
                            itemUuid: UUID().uuidString,
                            data: ItemContentData.wifi(.init(ssid: ssid,
                                                             password: password,
                                                             security: security,
                                                             extraSections: customSections)),
                            customFields: customFields)
    }
}
