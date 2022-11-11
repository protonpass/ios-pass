//
// SortType.swift
// Proton Pass - Created on 11/11/2022.
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

import Foundation

public enum SortType: CustomStringConvertible, CaseIterable {
    case title, type, createTime, modifyTime

    public var description: String {
        switch self {
        case .title: return "Title"
        case .type: return "Type"
        case .createTime: return "Creation date"
        case .modifyTime: return "Modification date"
        }
    }
}

public enum SortDirection: CustomStringConvertible, CaseIterable {
    case ascending, descending

    public var description: String {
        switch self {
        case .ascending: return "Ascending"
        case .descending: return "Descending"
        }
    }
}
