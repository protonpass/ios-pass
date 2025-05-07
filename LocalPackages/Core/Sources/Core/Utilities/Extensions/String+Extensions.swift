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

    var spacesRemoved: String {
        replacingOccurrences(of: " ", with: "")
    }

    // periphery:ignore
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
    // periphery:ignore
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

    func decodeHTMLAndPercentEntities() -> String {
        let decodedHTML = decodingHTMLEntities()
        return decodedHTML.removingPercentEncoding ?? decodedHTML
    }

    private func decodingHTMLEntities() -> String {
        guard let data = data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        } else {
            return self
        }
    }

    func replaceAllCharsExceptFirstAndLast(withChar newChar: Character) -> String {
        guard count > 2,
              let firstChar = first,
              let lastChar = last else { return self } // Return the original string if it's too short

        let startIndex = index(after: startIndex)
        let endIndex = index(before: endIndex)
        let middleCount = distance(from: startIndex, to: endIndex)

        let middleReplacement = String(repeating: newChar, count: middleCount)
        return "\(firstChar)\(middleReplacement)\(lastChar)"
    }

    static func concatenateOptionalStrings(_ strings: [String?], separator: String = "") -> String {
        // Filter out nil values and empty strings, then unwrap the non-nil, non-empty values
        let nonNilNonEmptyStrings = strings.compactMap { $0?.isEmpty == false ? $0 : nil }
        // Join the non-nil, non-empty strings with a space separator
        return nonNilNonEmptyStrings.joined(separator: separator)
    }

    // periphery:ignore
    static func concatenateOptionalStrings(_ strings: String?..., separator: String = "") -> String {
        // Call the array-based function with the variadic arguments
        concatenateOptionalStrings(strings, separator: separator)
    }

    func concatenateWith(_ strings: String?..., separator: String = "") -> String {
        var content: [String?] = [self]
        content.append(contentsOf: strings)
        return String.concatenateOptionalStrings(content, separator: separator)
    }

    var accentsRemoved: String {
        folding(options: .diacriticInsensitive, locale: .init(identifier: "en_US"))
    }
}

// MARK: Computed Extensions

public extension Substring {
    var toString: String { String(self) }
}
