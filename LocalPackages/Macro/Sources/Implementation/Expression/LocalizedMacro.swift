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
///     #localized("Hello world", bundle: .main)
///     #localized("Hello %@", "world")
///     #localized("Hello %@", bundle: .module, "world")
///
/// will expand to
///
///     String(localized: "Hello world")
///     String(localized: "Hello world", bundle: .main)
///     String(format: String(localized: "Hello %@"), "world")
///     String(format: String(localized: "Hello %@", bundle: .module), "world")
public struct LocalizedMacro: ExpressionMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                 in context: some MacroExpansionContext) throws -> ExprSyntax {
        guard !node.arguments.isEmpty else {
            throw MacroError.noArguments
        }

        let localizeKey = try getLocalizeKeyValue(from: node)
        let bundle = getBundleValue(from: node)
        let formatArgs = getFormatArgs(from: node)

        if formatArgs.isEmpty {
            if let bundle {
                return "String(localized: \(localizeKey), bundle: \(bundle))"
            } else {
                return "String(localized: \(localizeKey))"
            }
        } else {
            if let bundle {
                return "String(format: String(localized: \(localizeKey), bundle: \(bundle)), \(formatArgs))"
            } else {
                return "String(format: String(localized: \(localizeKey)), \(formatArgs))"
            }
        }
    }
}

private func getLocalizeKeyValue(from node: some FreestandingMacroExpansionSyntax) throws -> ExprSyntax {
    // Localize key as the first argument
    guard let firstArgument = node.arguments.first?.expression,
          let segments = firstArgument.as(StringLiteralExprSyntax.self)?.segments,
          segments.count == 1,
          case let .stringSegment(stringSegment) = segments.first else {
        throw MacroError.message(LocalizedMacro.Error.firstArgumentMustBeAString)
    }

    guard !stringSegment.content.text.isEmpty else {
        throw MacroError.message(LocalizedMacro.Error.emptyLocalizedKey)
    }
    return firstArgument
}

private func getBundleValue(from node: some FreestandingMacroExpansionSyntax) -> ExprSyntax? {
    node.arguments.first(where: { $0.label?.text == "bundle" })?.expression
}

private func getFormatArgs(from node: some FreestandingMacroExpansionSyntax) -> LabeledExprListSyntax {
    let localizekey = node.arguments.first
    let bundle = node.arguments.first { $0.label?.text == "bundle" }
    return node.arguments.filter { $0 != localizekey && $0 != bundle }
}

private extension LocalizedMacro {
    enum Error: Swift.Error {
        static let firstArgumentMustBeAString = "The first argument has to be a static string literal"
        static let emptyLocalizedKey = "Localized key can not be empty"
        static let noBundleArgument = "No bundle argument"
    }
}
