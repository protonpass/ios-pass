//
// WordProvider.swift
// Proton Pass - Created on 09/05/2023.
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

import Foundation

public enum DiceValue: Int, CaseIterable {
    case one = 1, two = 2, three = 3, four = 4, five = 5, six = 6

    // https://developer.apple.com/documentation/swift/randomnumbergenerator
    static func random(using generator: inout some RandomNumberGenerator) -> DiceValue {
        DiceValue.allCases.randomElement(using: &generator) ?? .one
    }

    static func random() -> DiceValue {
        var generator = SystemRandomNumberGenerator()
        return DiceValue.random(using: &generator)
    }
}

public struct DiceResult {
    let first: DiceValue
    let second: DiceValue
    let third: DiceValue
    let fourth: DiceValue
    let fifth: DiceValue

    public static func random() -> DiceResult {
        .init(first: .random(),
              second: .random(),
              third: .random(),
              fourth: .random(),
              fifth: .random())
    }

    var stringValue: String {
        "\(first.rawValue)\(second.rawValue)\(third.rawValue)\(fourth.rawValue)\(fifth.rawValue)"
    }
}

public protocol WordProviderProtocol {
    func word(for result: DiceResult) -> String
}

public final class WordProvider: WordProviderProtocol {
    private let dictionary: [String: String]

    public init() async throws {
        guard let url = Bundle.current.url(forResource: "eff_large_wordlist", withExtension: "txt") else {
            fatalError("Failed to load wordlist")
        }

        var dict = [String: String]()
        for try await line in url.lines {
            let words = line.components(separatedBy: "\t")
            if words.count == 2, let key = words.first, let value = words.last {
                dict[key] = value
            }
        }

        assert(dict.keys.count == 7_776, "Corrupted dictionary")

        dictionary = dict
    }

    public func word(for result: DiceResult) -> String {
        let word = dictionary[result.stringValue]
        assert(word != nil, "Word not found for key \(result.stringValue)")
        return word ?? ""
    }
}
