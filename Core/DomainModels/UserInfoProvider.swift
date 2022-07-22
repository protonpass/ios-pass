//
// UserInfoProvider.swift
// Proton Pass - Created on 15/07/2022.
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

import ProtonCore_DataModel

/// Properties with `userInfo` prefix to avoid name collapsing
public protocol UserInfoProvider {
    var userInfoInitials: String { get }
    var userInfoDisplayName: String { get }
    var userInfoEmail: String { get }
}

extension User: UserInfoProvider {
    public var userInfoInitials: String { userInfoDisplayName.initials() }
    public var userInfoDisplayName: String { displayName ?? name ?? "" }
    public var userInfoEmail: String { email ?? "" }
}
