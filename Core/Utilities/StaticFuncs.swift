//
// StaticFuncs.swift
// Proton Pass - Created on 22/07/2022.
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

public func unwrap<T>(caller: StaticString = #function, action: () -> T?) throws -> T {
    let optional = action()
    if let optional { return optional }
    throw NSError(domain: "Expected honest \(T.self), but found nil instead. \nCaller: \(caller)", code: 1)
}

public func throwing<T>(operation: (inout NSError?) -> T) throws -> T {
    var error: NSError?
    let result = operation(&error)
    if let error { throw error }
    return result
}
