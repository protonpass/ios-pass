//
// StringExtensions.swift
// Proton Pass - Created on 08/07/2022.
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

import CryptoKit
import Foundation

public enum AllowedCharacter: String {
    case lowercase = "abcdefghjkmnpqrstuvwxyz"
    case uppercase = "ABCDEFGHJKMNPQRSTUVWXYZ"
    case digit = "0123456789"
    case special = "!#$%&()*+.:;<=>?@[]^"
}

// swiftlint:disable force_unwrapping
public extension String {
    static func random(allowedCharacters: [AllowedCharacter] = [.lowercase, .uppercase, .digit],
                       length: Int = 10) -> String {
        let allCharacters = allowedCharacters.map { $0.rawValue }.reduce(into: "") { $0 += $1 }
        // swiftlint:disable:next todo
        // TODO: Make sure that returned string contains at least 1 character from each AllowedCharacter set
        return String((0..<length).map { _ in allCharacters.randomElement()! })
    }

    func base64Decode() throws -> Data? { Data(base64Encoded: self) }

    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }

    /// All capitalized. Maximum 2 characters.
    func initialsRemovingEmojis() -> String {
        let noEmojisString = String(unicodeScalars.filter { !$0.properties.isEmoji })

        let first2Words = noEmojisString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ")
            .prefix(2)

        if first2Words.count == 2,
           let firstFirstChar = first2Words.first?.first,
           let secondChar = first2Words.last?.first {
            return String([firstFirstChar, secondChar]).uppercased()
        }

        return String(first2Words.first?.prefix(2) ?? "").uppercased()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
