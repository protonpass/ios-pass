//
// KeychainMock.swift
// Proton Pass - Created on 23/02/2023.
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

import Core
import Foundation
import ProtonCoreTestingToolkitUnitTestsCore

final class KeychainMock: KeychainProtocol {
    @FuncStub(KeychainMock.data, initialReturn: nil) var dataStub

    func data(forKey key: String, attributes: [CFString: Any]?) -> Data? { dataStub(key, attributes) }

    @FuncStub(KeychainMock.string, initialReturn: nil) var stringStub

    func string(forKey key: String, attributes: [CFString: Any]?) -> String? { stringStub(key, attributes) }

    @FuncStub(KeychainMock.set(data:forKey:attributes:)) var setDataStub

    private func set(data: Data, forKey key: String, attributes: [CFString: Any]? ) { setDataStub(data, key, attributes) }
    func set(_ data: Data, forKey key: String, attributes: [CFString: Any]?) { set(data: data, forKey: key, attributes: attributes) }

    @FuncStub(KeychainMock.set(string:forKey:attributes:)) var setStringStub

    private func set(string: String, forKey key: String, attributes: [CFString: Any]?) { setStringStub(string, key, attributes) }
    func set(_ string: String, forKey key: String, attributes: [CFString: Any]?) { set(string: string, forKey: key, attributes: attributes) }

    @FuncStub(KeychainMock.remove) var removeStub

    func remove(forKey key: String) { removeStub(key) }
}
