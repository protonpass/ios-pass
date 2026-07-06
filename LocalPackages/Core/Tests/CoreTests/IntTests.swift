//  
// IntTests.swift
// Proton Pass - Created on 06/07/2026.
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

import Core
import Foundation
import Testing

struct IntTests {
    let containerUrl = FileUtils.getDocumentsDirectory()
    
    @Test
    func `clamp keeps a value that is already within range`() {
        #expect(10.clamp(to: 4...64) == 10)
    }
    
    @Test
    func `clamp raises a value below the lower bound`() {
        #expect(2.clamp(to: 4...64) == 4)
    }
    
    @Test
    func `clamp lowers a value above the upper bound`() {
        #expect(80.clamp(to: 4...64) == 64)
    }
}
