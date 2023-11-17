//
// ClipboardManager.swift
// Proton Pass - Created on 26/12/2022.
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
import DesignSystem
import Factory
import UIKit

protocol ClipboardManagerProtocol: Sendable {
    func copy(text: String, bannerMessage: String)
}

final class ClipboardManager: ClipboardManagerProtocol {
    private let preferences: PreferencesProtocol
    let bannerManager: BannerDisplayProtocol

    init(bannerManager: BannerDisplayProtocol,
         preferences: PreferencesProtocol) {
        self.bannerManager = bannerManager
        self.preferences = preferences
    }

    func copy(text: String, bannerMessage: String) {
        UIPasteboard.general.setObjects([NSString(string: text)],
                                        localOnly: !preferences.shareClipboard,
                                        expirationDate: preferences.clipboardExpiration.expirationDate)
        bannerManager.displayBottomInfoMessage(bannerMessage)
    }
}
