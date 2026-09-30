//
// Data+BreachRange.swift
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

struct BreachRangeEntry: Equatable {
    let suffix: String
    let count: Int
}

extension BreachRangeEntry {
    init?(line: Substring) {
        let parts = line.split(separator: ":", maxSplits: 1)
        guard parts.count == 2 else {
            return nil
        }
        suffix = parts[0].trimmingCharacters(in: .whitespaces).uppercased()
        count = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
    }
}

extension Data {
    /// Parses a k-anonymity range body of `SUFFIX:COUNT` lines. Padding entries (from `Add-Padding`)
    /// simply never match a real suffix, so they are harmless.
    func parseBreachRange() -> [BreachRangeEntry] {
        guard let text = String(data: self, encoding: .utf8) else {
            return []
        }
        return text.split(whereSeparator: \.isNewline).compactMap(BreachRangeEntry.init(line:))
    }
}

extension [BreachRangeEntry] {
    var countsBySuffix: [String: Int] {
        Dictionary(map { ($0.suffix, $0.count) }) { _, last in last }
    }
}
