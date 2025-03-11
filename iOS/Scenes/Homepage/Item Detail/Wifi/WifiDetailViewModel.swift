//
// WifiDetailViewModel.swift
// Proton Pass - Created on 10/03/2025.
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

final class WifiDetailViewModel: BaseItemDetailViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var ssid = ""
    @Published private(set) var password = ""
    @Published private(set) var security: WifiData.Security = .unspecified

    var extraSections: [CustomSection] {
        itemContent.wifi?.extraSections ?? []
    }

    override func bindValues() {
        super.bindValues()
        if case let .wifi(data) = itemContent.contentData {
            ssid = data.ssid
            password = data.password
            security = data.security
        } else {
            fatalError("Expecting wifi type")
        }
    }
}

extension WifiDetailViewModel {
    func copySsid() {
        guard !ssid.isEmpty else { return }
        copyToClipboard(text: ssid, message: "SSID copied")
    }

    func copyPassword() {
        guard !password.isEmpty else { return }
        copyToClipboard(text: password, message: "WiFi password copied")
    }

    func showLargePassword() {
        showLarge(.password(password))
    }
}
