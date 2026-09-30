//
// Gunzipper.swift
// Proton Pass - Created on 30/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import PassRustCore

public protocol GunzipperProtocol: Sendable {
    func unzip(_ data: Data) throws -> Data
}

public struct Gunzipper: GunzipperProtocol {
    private let gzip: any PassGzipProtocol

    public init(gzip: any PassGzipProtocol = PassGzip()) {
        self.gzip = gzip
    }

    public func unzip(_ data: Data) throws -> Data {
        try gzip.gunzip(input: data)
    }
}
