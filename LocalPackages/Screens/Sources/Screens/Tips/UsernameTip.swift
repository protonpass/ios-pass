//
// UsernameTip.swift
// Proton Pass - Created on 03/05/2024.
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
public struct UsernameTip: Tip {
    public var id: String { PassTip.username.id }

    @Parameter
    public static var enabled: Bool = false

    public var rules: [Rule] {
        [#Rule(Self.$enabled) { $0 == true }]
    }

    public var title: Text {
        Text("Add username field", bundle: .module)
            .foregroundStyle(PassColor.textNorm)
    }

    public var message: Text? {
        Text("Tap here to add a field for a username.", bundle: .module)
            .foregroundStyle(PassColor.textWeak)
    }

    public var image: Image? {
        nil
    }

    public var options: [TipOption] {
        // Show this tip once
        Tips.MaxDisplayCount(1)
    }

    public init() {}
}
