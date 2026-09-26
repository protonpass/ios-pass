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
import UniformTypeIdentifiers

/// Copy `text` to clipboard and optionally display a banner message
@MainActor
public protocol CopyToClipboardUseCase: Sendable {
    func callAsFunction(_ text: String,
                        expirationDate: Date?,
                        bannerMessage: String?,
                        bannerDisplay: (any BannerDisplayProtocol)?)
}

public extension CopyToClipboardUseCase {
    func callAsFunction(_ text: String,
                        expirationDate: Date? = nil,
                        bannerMessage: String? = nil,
                        bannerDisplay: (any BannerDisplayProtocol)? = nil) {
        callAsFunction(text,
                       expirationDate: expirationDate,
                       bannerMessage: bannerMessage,
                       bannerDisplay: bannerDisplay)
    }
}

public struct CopyToClipboard: CopyToClipboardUseCase {
    private let getSharedPreferences: any GetSharedPreferencesUseCase

    public nonisolated init(getSharedPreferences: any GetSharedPreferencesUseCase) {
        self.getSharedPreferences = getSharedPreferences
    }

    public func callAsFunction(_ text: String,
                               expirationDate: Date?,
                               bannerMessage: String?,
                               bannerDisplay: (any BannerDisplayProtocol)?) {
        let preferences = getSharedPreferences()

        // Use setItems with raw Data instead of setObjects with NSItemProviderWriting.
        // setObjects creates data-loading blocks that become unreadable when the
        // extension process terminates (e.g. AutoFill). Providing Data directly
        // ensures the content persists and expiration is tracked by the system.
        let items: [[String: Any]] = [[UTType.utf8PlainText.identifier: Data(text.utf8)]]
        var options: [UIPasteboard.OptionsKey: Any] = [
            .localOnly: !preferences.shareClipboard
        ]
        // Use caller-provided expiration if set, otherwise fall back to user preference
        let effectiveExpiration = expirationDate ?? preferences.clipboardExpiration.expirationDate
        if let effectiveExpiration {
            options[.expirationDate] = effectiveExpiration
        }
        UIPasteboard.general.setItems(items, options: options)

        if let bannerMessage {
            assert(bannerDisplay != nil, "Banner display should be set to display banner message")
            bannerDisplay?.displayBottomInfoMessage(bannerMessage)
        }
    }
}
