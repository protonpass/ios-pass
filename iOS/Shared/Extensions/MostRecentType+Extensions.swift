//
// MostRecentType+Extensions.swift
// Proton Pass - Created on 18/10/2024.
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

import Client
import Macro

public extension MostRecentType {
    var title: String {
        switch self {
        case .today:
            #localized("Today")
        case .yesterday:
            #localized("Yesterday")
        case .last7Days:
            #localized("Last week")
        case .last14Days:
            #localized("Last two weeks")
        case .last30Days:
            #localized("Last 30 days")
        case .last60Days:
            #localized("Last 60 days")
        case .last90Days:
            #localized("Last 90 days")
        case .others:
            #localized("More than 90 days")
        }
    }
}
