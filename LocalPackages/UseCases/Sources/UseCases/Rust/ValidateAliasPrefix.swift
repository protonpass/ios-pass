//
//
// ValidateAliasPrefix.swift
// Proton Pass - Created on 28/09/2023.
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
@preconcurrency import PassRustCore

public protocol ValidateAliasPrefixUseCase: Sendable {
    func execute(prefix: String) throws
}

public extension ValidateAliasPrefixUseCase {
    func callAsFunction(prefix: String) throws {
        try execute(prefix: prefix)
    }
}

public final class ValidateAliasPrefix: ValidateAliasPrefixUseCase {
    private let validator: any AliasPrefixValidatorProtocol

    public init(validator: any AliasPrefixValidatorProtocol = AliasPrefixValidator()) {
        self.validator = validator
    }

    public func execute(prefix: String) throws {
        do {
            try validator.validate(prefix: prefix)
        } catch {
            guard let aliasError = error as? PassRustCore.AliasPrefixError else {
                throw Entities.AliasPrefixError.unknown
            }
            throw aliasError.toEntitiesAliasPrefixError
        }
    }
}

extension PassRustCore.AliasPrefixError {
    var toEntitiesAliasPrefixError: Entities.AliasPrefixError {
        switch self {
        case .DotAtTheBeginning:
            .dotAtTheStart
        case .DotAtTheEnd:
            .dotAtTheEnd
        case .InvalidCharacter:
            .disallowedCharacters
        case .PrefixEmpty:
            .emptyPrefix
        case .PrefixTooLong:
            .prefixToLong
        case .TwoConsecutiveDots:
            .twoConsecutiveDots
        }
    }
}
