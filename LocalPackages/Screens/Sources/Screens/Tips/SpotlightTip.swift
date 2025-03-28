//
// SpotlightTip.swift
// Proton Pass - Created on 22/03/2024.
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
public struct SpotlightTip: Tip {
    public var id: String { PassTip.spotlight.id }

    @Parameter
    public static var spotlightEnabled: Bool = false
    public static let didPerformSearch = Event(id: "didPerformSearch")

    public var rules: [Rule] {
        [
            #Rule(Self.$spotlightEnabled) { $0 == false },
            #Rule(Self.didPerformSearch) { $0.donations.count >= 10 }
        ]
    }

    public var title: Text {
        Text("Enable Spotlight search", bundle: .module)
            .foregroundStyle(PassColor.textNorm.toColor)
    }

    public var message: Text? {
        Text("Seamlessly search for items via your home screen. Open Settings → Spotlight to enable.",
             bundle: .module)
            .foregroundStyle(PassColor.textWeak.toColor)
    }

    public var image: Image? {
        Image(systemName: "magnifyingglass.circle.fill")
    }

    public var options: [TipOption] {
        // Show this tip once
        Tips.MaxDisplayCount(1)
    }

    public var actions: [Action] {
        [
            PassTipAction.openSettings.toAction()
        ]
    }

    public init() {}
}
