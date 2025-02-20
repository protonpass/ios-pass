//
// IsUITestModeKey.swift
// Proton Pass - Created on 2025. 02. 14..
// Copyright (c) 2025 Proton Technologies AG
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

import SwiftUI

private struct RunningInUITests: EnvironmentKey {
    static let defaultValue: Bool = ProcessInfo.processInfo.arguments.contains("RunningInUITests")
}

extension EnvironmentValues {
    var runningInUITests: Bool {
        self[RunningInUITests.self]
    }
}
