//
// PassTip.swift
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

import Foundation
import Macro
import TipKit

enum PassTip: String {
    case itemForceTouch
    case spotlight
    case username

    var id: String { rawValue }
}

public enum PassTipAction: String {
    /// Open Pass settings, not iOS settings
    case openSettings

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .openSettings:
            #localized("Open Settings", bundle: .module)
        }
    }

    @available(iOS 17, *)
    public func toAction() -> Tip.Action {
        .init(id: id, title: title)
    }
}

@available(iOS 17, *)
public extension Tip.Action {
    func `is`(_ action: PassTipAction) -> Bool {
        id == action.id
    }
}
