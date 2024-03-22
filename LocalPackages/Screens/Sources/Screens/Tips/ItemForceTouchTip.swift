//
// ItemForceTouchTip.swift
// Proton Pass - Created on 21/03/2024.
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

import DesignSystem
import TipKit

@available(iOS 17, *)
public struct ItemForceTouchTip: Tip {
    public var id: String { PassTip.itemForceTouch.id }

    // As this tip is shown on top of the item list which could have an above banner section
    // we show this tip only when no other banners are displayed to make room for items
    @Parameter
    // swiftlint:disable:next redundant_type_annotation
    public static var allBannersDismissed: Bool = false

    // Tap to copy items' detail like username or password
    public static let didTapToCopy = Event(id: "didTapToCopy")
    public static let didEdit = Event(id: "didEdit")
    public static let didTogglePin = Event(id: "didTogglePin")
    public static let didTrash = Event(id: "didTrash")

    public var rules: [Rule] {
        [
            #Rule(Self.$allBannersDismissed) { $0 == true },
            #Rule(Self.didTapToCopy) { $0.donations.count >= 10 },
            #Rule(Self.didEdit) { $0.donations.count >= 10 },
            #Rule(Self.didTogglePin) { $0.donations.count >= 10 },
            #Rule(Self.didTrash) { $0.donations.count >= 10 }
        ]
    }

    public var title: Text {
        Text(verbatim: "Quick actions on items")
            .foregroundStyle(PassColor.textNorm.toColor)
    }

    public var message: Text? {
        Text(verbatim: "Press and hold an item to reveal extra options.")
            .foregroundStyle(PassColor.textWeak.toColor)
    }

    public var image: Image? {
        Image(systemName: "hand.tap.fill")
    }

    public var options: [TipOption] {
        // Show this tip once
        Tips.MaxDisplayCount(1)
    }

    public init() {}
}
