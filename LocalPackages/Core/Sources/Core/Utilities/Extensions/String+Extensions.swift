//
// String+Extensions.swift
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
    case separator = "-.,_"
}

public extension String {
    static func random(allowedCharacters: [AllowedCharacter] = [.lowercase, .uppercase, .digit],
                       length: Int = 10) -> String {
        let allCharacters = allowedCharacters.map(\.rawValue).reduce(into: "") { $0 += $1 }
        // swiftlint:disable:next todo
        // TODO: Make sure that returned string contains at least 1 character from each AllowedCharacter set
        return String((0..<length).compactMap { _ in allCharacters.randomElement() })
    }

    func base64Decode() throws -> Data? { Data(base64Encoded: self) }

    func capitalizingFirstLetter() -> String {
        prefix(1).capitalized + dropFirst()
    }

    /// All capitalized. Maximum 2 characters.
    func initials() -> String {
        let first2Words = trimmingCharacters(in: .whitespacesAndNewlines)
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
        self = capitalizingFirstLetter()
    }

    var spacesRemoved: String {
        replacingOccurrences(of: " ", with: "")
    }

    func characterCount(_ character: Character) -> Int {
        filter { $0 == character }.count
    }

    func toCreditCardNumber() -> String {
        // Amex format: NNNN-NNNNNN-NNNNN (4-6-5)
        let isAmex = ["34", "37"].contains(prefix(2))

        let noSpacesCardNumber = spacesRemoved

        // Only consider amex card if number of character <= 15
        // otherwise treat it as normal card
        if isAmex, noSpacesCardNumber.count <= 15 {
            var formatted = noSpacesCardNumber
            if formatted.count > 4 {
                formatted.insert(" ", at: formatted.index(formatted.startIndex, offsetBy: 4))
            }
            if formatted.count > 11 {
                formatted.insert(" ", at: formatted.index(formatted.startIndex, offsetBy: 11))
            }
            return formatted
        } else {
            let chunks = Array(noSpacesCardNumber).chunked(into: 4)
            return chunks.map { String($0) }.joined(separator: " ")
        }
    }

    func toMaskedCreditCardNumber() -> String {
        guard count >= 12 else {
            return "•••• •••• •••• ••••"
        }
        let isAmex = ["34", "37"].contains(prefix(2))

        let noSpacesCardNumber = spacesRemoved

        if isAmex, count == 15 {
            return "\(noSpacesCardNumber.prefix(4)) •••••• \(noSpacesCardNumber.suffix(5))"
        } else {
            let chunks = Array(noSpacesCardNumber).chunked(into: 4)
            var formatted = ""

            for (index, chunk) in chunks.enumerated() {
                if index == 0 {
                    formatted += String(chunk)
                } else if index == chunks.count - 1 {
                    formatted += " \(String(chunk))"
                } else {
                    formatted += " ••••"
                }
            }

            return formatted
        }
    }

    // https://www.hackingwithswift.com/example-code/strings/how-to-detect-a-url-in-a-string-using-nsdatadetector
    func firstUrl() -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }

        let matches = detector.matches(in: self, range: .init(location: 0, length: utf16.count))
        for match in matches {
            guard let range = Range(match.range, in: self),
                  let url = URL(string: String(self[range]).lowercased()) else { continue }
            return url
        }
        return nil
    }
}

// MARK: Computed Extensions

public extension String {
    var toBase8EncodedData: Data? {
        data(using: .utf8)
    }
}

public extension Substring {
    var toString: String { String(self) }
}
