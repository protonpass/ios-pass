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

/// Implementation of the `localized` macro, which converts a static literal string into a localized one
/// For example,
///
///     #localized("Welcome to Proton")
///
/// will expand to
///
///     String(localized: "Welcome to Proton")
public struct LocalizedMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard let firstArgument = node.argumentList.first?.expression else {
            throw MacroError.message("The macro does not have any arguments")
        }

        // First argument always has to be a string
        guard let firstArgumentSegments = firstArgument.as(StringLiteralExprSyntax.self)?.segments,
              firstArgumentSegments.count == 1,
              case let .stringSegment(firstArgumentStringSegment) = firstArgumentSegments.first else {
            throw MacroError.message("The first argument has to be a static string literal")
        }

        guard !firstArgumentStringSegment.content.text.isEmpty else {
            throw MacroError.message("Localized key can not be empty")
        }

        return "String(localized: \(firstArgument))"
    }
}
