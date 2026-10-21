//
// Data+HmacSecretSaltTests.swift
// Proton Pass - Created on 21/10/2026.
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

import Entities
import Foundation
import Testing

@Suite(.tags(.extension))
struct DataHmacSecretSaltTests {
    @Test func `value that is already 32 bytes is returned unchanged`() {
        let value = Data(repeating: 1, count: 32)

        #expect(value.hmacSecretSalt == value)
    }

    @Test(arguments: [
        (Data("first".utf8), "e9dfe497cb7e3b350ab7e7e0103b46142e37aefda2bf9cf576d6b94a4762aa35"),
        (Data(), "6a7e64b2aa34c92736143a062fa149aff1bd8bb3f7ee6f346885481f9414a3d3"),
        (Data(repeating: 7, count: 31), "b7b1cf96d4184a6c855b6bcbc060de6864f5e976de9d56f8f508b914ce2020d8"),
        (Data(repeating: 7, count: 33), "780fe65cbfccce68d59c439ed8efc674f176082ca9dd83e3ea0e7ea5007456c6")
    ])
    func `value of any other length is hashed with the WebAuthn PRF prefix`(value: Data, expectedHex: String) {
        let hex = value.hmacSecretSalt.map { String(format: "%02x", $0) }.joined()

        #expect(hex == expectedHex)
    }
}
