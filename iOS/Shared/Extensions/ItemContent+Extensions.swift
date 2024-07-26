//
// ItemContent+Extensions.swift
// Proton Pass - Created on 30/01/2024.
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

import Entities

extension ItemContent {
    func updateTotp(uri: String) -> ItemContent {
        guard let data = loginItem else {
            return self
        }
        let updatedData = LogInItemData(email: data.email,
                                        username: data.username,
                                        password: data.password,
                                        totpUri: uri,
                                        urls: data.urls,
                                        allowedAndroidApps: data.allowedAndroidApps,
                                        passkeys: data.passkeys)
        return ItemContent(shareId: shareId,
                           itemUuid: itemUuid,
                           userId: userId,
                           item: item,
                           name: name,
                           note: note,
                           contentData: .login(updatedData),
                           customFields: customFields)
    }
}
