// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
// Copyright (c) 2023 Proton Technologies AG
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
import Foundation
import PassRustCore

public final class GunzipperProtocolMock: @unchecked Sendable, GunzipperProtocol {

    public init() {}

    // MARK: - unzip
    public var unzipThrowableError1: Error?
    public var closureUnzip: () -> () = {}
    public var invokedUnzipfunction = false
    public var invokedUnzipCount = 0
    public var invokedUnzipParameters: (data: Data, Void)?
    public var invokedUnzipParametersList = [(data: Data, Void)]()
    public nonisolated(unsafe) var stubbedUnzipResult: Data!

    public func unzip(_ data: Data) throws -> Data {
        invokedUnzipfunction = true
        invokedUnzipCount += 1
        invokedUnzipParameters = (data, ())
        if let error = unzipThrowableError1 {
            throw error
        }
        closureUnzip()
        return stubbedUnzipResult
    }
}
