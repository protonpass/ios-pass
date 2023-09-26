//
// LocalizedMacro.swift
// Proton Pass - Created on 25/09/2023.
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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `#localized` macro, which converts a static literal string with optional arguments into a
/// localized one. For example:
///
///     #localized("Hello world")
///     #localized("Hello %@", "world")
///
/// will expand to
///
///     String(localized: "Hello world")
///     String(format: String(localized: "Hello %@"), "world")
public struct LocalizedMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard let firstArgument = node.argumentList.first?.expression else {
            throw MacroError.noArguments
        }

        // First argument always has to be a string
        guard let firstArgumentSegments = firstArgument.as(StringLiteralExprSyntax.self)?.segments,
              firstArgumentSegments.count == 1,
              case let .stringSegment(firstArgumentStringSegment) = firstArgumentSegments.first else {
            throw MacroError.message(LocalizedMacroError.firstArgumentMustBeAString)
        }

        guard !firstArgumentStringSegment.content.text.isEmpty else {
            throw MacroError.message(LocalizedMacroError.emptyLocalizedKey)
        }

        if node.argumentList.count == 1 {
            return "String(localized: \(firstArgument))"
        }

        let lastArguments = node.argumentList.filter { $0.expression != firstArgument }
        return "String(format: String(localized: \(firstArgument)), \(lastArguments))"
    }
}

enum LocalizedMacroError {
    static let firstArgumentMustBeAString = "The first argument has to be a static string literal"
    static let emptyLocalizedKey = "Localized key can not be empty"
}
