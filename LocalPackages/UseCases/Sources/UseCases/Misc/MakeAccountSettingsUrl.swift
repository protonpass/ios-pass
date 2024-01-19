//
// MakeAccountSettingsUrl.swift
// Proton Pass - Created on 19/01/2024.
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

import Entities
import Foundation
@preconcurrency import ProtonCoreDoh

public protocol MakeAccountSettingsUrlUseCase: Sendable {
    func execute() throws -> String
}

public extension MakeAccountSettingsUrlUseCase {
    func callAsFunction() throws -> String {
        try execute()
    }
}

public final class MakeAccountSettingsUrl: MakeAccountSettingsUrlUseCase {
    private let doh: any DoHInterface

    public init(doh: any DoHInterface) {
        self.doh = doh
    }

    public func execute() throws -> String {
        let urlString = "\(doh.getAccountHost())/pass/account-password"
        guard URL(string: urlString) != nil else {
            throw PassError.invalidUrl(urlString)
        }
        return urlString
    }
}
