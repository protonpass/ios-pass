//
//  String+Extensions.swift
//  DocScannerDemo
//
//  Created by martin on 26/08/2023.
//

import Foundation
import RegexBuilder

extension String {
    var isLowercase: Bool {
        self == lowercased()
    }

    var isUppercase: Bool {
        self == uppercased()
    }

    var isNumber: Bool {
        range(of: "^[0-9]*$",
              options: .regularExpression) != nil
    }

    var spaceTrimmed: String {
        replacingOccurrences(of: " ", with: "")
    }

    var fullRange: NSRange {
        NSRange(location: 0, length: count)
    }

    var nameRegexChecked: Bool {
        if #available(iOS 16, *) {
            let regex = Regex {
                Optionally {
                    Repeat(2...3) {
                        CharacterClass("A"..."Z")
                    }
                    Optionally {
                        "."
                    }
                }

                Repeat(3...24) {
                    CharacterClass(.anyOf("'"),
                                   "A"..."Z")
                }
                Optionally {
                    "."
                }
                One(.whitespace)
                Repeat(3...23) {
                    CharacterClass(.anyOf("'"),
                                   "A"..."Z",
                                   .whitespace)
                }
                Optionally {
                    "."
                }
            }
            return self.contains(regex)
        } else {
            let namePatternCheck = #"""
            ^[A-Z']{1,24}\.?\s[A-Z][A-Z'\s]{3,23}\.?$
            """#
            if let regex = try? NSRegularExpression(pattern: namePatternCheck,
                                                    options: .allowCommentsAndWhitespace),
                regex.matches(in: self).isEmpty {
                return false
            }
            return true
        }
    }
}
