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

    /// Any actions that is accessible via context menu like copy username/password, pin/unpin or trash, etc...
    public static let didPerformEligibleQuickAction = Event(id: "didPerformEligibleQuickAction")

    public var rules: [Rule] {
        [
            #Rule(Self.didPerformEligibleQuickAction) { $0.donations.count >= 10 }
        ]
    }

    public var title: Text {
        Text("Quick actions on items", bundle: .module)
            .foregroundStyle(PassColor.textNorm)
    }

    public var message: Text? {
        Text("Press and hold an item to reveal extra options.", bundle: .module)
            .foregroundStyle(PassColor.textWeak)
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
