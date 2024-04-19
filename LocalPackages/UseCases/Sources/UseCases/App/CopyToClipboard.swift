//
// CopyToClipboard.swift
// Proton Pass - Created on 16/04/2024.
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
//

import Client
import Foundation
import UIKit

/// Copy `text` to clipboard and optionally display a banner message
public protocol CopyToClipboardUseCase: Sendable {
    func execute(_ text: String,
                 bannerMessage: String?,
                 bannerDisplay: (any BannerDisplayProtocol)?)
}

public extension CopyToClipboardUseCase {
    func callAsFunction(_ text: String,
                        bannerMessage: String? = nil,
                        bannerDisplay: (any BannerDisplayProtocol)? = nil) {
        execute(text, bannerMessage: bannerMessage, bannerDisplay: bannerDisplay)
    }
}

public final class CopyToClipboard: CopyToClipboardUseCase {
    private let getSharedPreferences: any GetSharedPreferencesUseCase

    public init(getSharedPreferences: any GetSharedPreferencesUseCase) {
        self.getSharedPreferences = getSharedPreferences
    }

    public func execute(_ text: String,
                        bannerMessage: String?,
                        bannerDisplay: (any BannerDisplayProtocol)?) {
        let preferences = getSharedPreferences()
        UIPasteboard.general.setObjects([NSString(string: text)],
                                        localOnly: !preferences.shareClipboard,
                                        expirationDate: preferences.clipboardExpiration.expirationDate)
        if let bannerMessage {
            assert(bannerDisplay != nil, "Banner display should be set to display banner message")
            bannerDisplay?.displayBottomInfoMessage(bannerMessage)
        }
    }
}
