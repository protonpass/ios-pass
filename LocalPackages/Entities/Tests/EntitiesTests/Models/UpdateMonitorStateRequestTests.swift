//
// UpdateMonitorStateRequestTests.swift
// Proton Pass - Created on 22/04/2024.
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
import Testing

@Suite(.tags(.entity))
struct UpdateMonitorStateRequestTests {
    @Test(arguments: [(UpdateMonitorStateRequest.protonAddress(true), "{\"ProtonAddress\":true}"),
                      (UpdateMonitorStateRequest.protonAddress(false), "{\"ProtonAddress\":false}"),
                      (UpdateMonitorStateRequest.aliases(true), "{\"Aliases\":true}"),
                      (UpdateMonitorStateRequest.aliases(false), "{\"Aliases\":false}")])
    func `request encodes to its monitor state key`(request: UpdateMonitorStateRequest,
                                                    expected: String) throws {
        let data = try JSONEncoder().encode(request)
        #expect(String(data: data, encoding: .utf8) == expected)
    }
}
