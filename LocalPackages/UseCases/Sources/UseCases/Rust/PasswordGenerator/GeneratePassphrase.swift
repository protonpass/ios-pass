//
// GeneratePassphrase.swift
// Proton Pass - Created on 23/10/2023.
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
//

import Entities
import PassRustCore

public protocol GeneratePassphraseUseCase: Sendable {
    func execute(words: [String],
                 separator: Entities.WordSeparator,
                 capitalise: Bool,
                 includeNumbers: Bool) throws -> String
}

public extension GeneratePassphraseUseCase {
    func callAsFunction(words: [String],
                        separator: Entities.WordSeparator,
                        capitalise: Bool,
                        includeNumbers: Bool) throws -> String {
        try execute(words: words,
                    separator: separator,
                    capitalise: capitalise,
                    includeNumbers: includeNumbers)
    }
}

public final class GeneratePassphrase: GeneratePassphraseUseCase {
    public init() {}

    public func execute(words: [String],
                        separator: Entities.WordSeparator,
                        capitalise: Bool,
                        includeNumbers: Bool) throws -> String {
        let config = PassphraseConfig(separator: separator.toRustSeparator(),
                                      capitalise: capitalise,
                                      includeNumbers: includeNumbers,
                                      count: 0) // Not applicable
        return try PassphraseGenerator().generatePassphrase(words: words,
                                                            config: config)
    }
}

private extension Entities.WordSeparator {
    func toRustSeparator() -> PassRustCore.WordSeparator {
        switch self {
        case .hyphens:
            .hyphens
        case .spaces:
            .spaces
        case .periods:
            .periods
        case .commas:
            .commas
        case .underscores:
            .underscores
        case .numbers:
            .numbers
        case .numbersAndSymbols:
            .numbersAndSymbols
        }
    }
}
