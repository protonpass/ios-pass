//
// MakeImportExportUrl.swift
// Proton Pass - Created on 18/01/2024.
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

public protocol MakeImportExportUrlUseCase: Sendable {
    func execute(selector: String) throws -> URL
}

public extension MakeImportExportUrlUseCase {
    func callAsFunction(selector: String) throws -> URL {
        try execute(selector: selector)
    }
}

public final class MakeImportExportUrl: MakeImportExportUrlUseCase {
    private let doh: any DoHInterface

    public init(doh: any DoHInterface) {
        self.doh = doh
    }

    #warning("Make use of selector")
    public func execute(selector: String) throws -> URL {
        let urlString = "https://pass.\(doh.getSignUpString())"
        guard let url = URL(string: urlString) else {
            throw PassError.invalidUrl(urlString)
        }
        return url
    }
}
