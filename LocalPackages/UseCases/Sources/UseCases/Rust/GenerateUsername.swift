//
//
// GenerateUsername.swift
// Proton Pass - Created on 04/06/2026.
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
//

// periphery:ignore:all

import Client
import Entities
import PassRustCore

// swiftlint:disable function_parameter_count
public protocol GenerateUsernameUseCase: Sendable {
    func callAsFunction(wordCount: Int,
                        includeNumbers: Bool,
                        capitalise: Bool,
                        separator: Entities.WordSeparator,
                        leetSpeak: Bool,
                        wordTypes: Entities.WordTypes) throws -> String
}

public struct GenerateUsername: GenerateUsernameUseCase {
    private let generator: any UsernameGeneratorProtocol

    public init(_ generator: any UsernameGeneratorProtocol = UsernameGenerator()) {
        self.generator = generator
    }

    public func callAsFunction(wordCount: Int,
                               includeNumbers: Bool,
                               capitalise: Bool,
                               separator: Entities.WordSeparator,
                               leetSpeak: Bool,
                               wordTypes: Entities.WordTypes) throws -> String {
        let config = UsernameGeneratorConfig(wordCount: UInt32(wordCount),
                                             includeNumbers: includeNumbers,
                                             capitalise: capitalise,
                                             separator: separator.toRustSeparator,
                                             leetspeak: leetSpeak,
                                             wordTypes: wordTypes.toRustWordTypes)
        return try generator.generate(config: config)
    }
}

// swiftlint:enable function_parameter_count

extension Entities.WordTypes {
    var toRustWordTypes: PassRustCore.WordTypes {
        PassRustCore.WordTypes(adjectives: adjectives, nouns: nouns, verbs: verbs)
    }
}
