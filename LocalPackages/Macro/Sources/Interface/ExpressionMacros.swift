//
// ExpressionMacros.swift
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

/// A macro that converts a static literal string with optional arguments into a localized one
/// - Parameters:
///   - key: the localized key
///   - arguments: the list of arguments if the key contains format specifiers
@freestanding(expression)
public macro localized<each T>(_ key: StaticString, _ arguments: repeat each T)
    -> String = #externalMacro(module: "MacroImplementation", type: "LocalizedMacro")

/// A macro that converts a static literal string with optional arguments into a localized one
/// - Parameters:
///   - key: the localized key
@freestanding(expression)
public macro localized(_ key: StaticString) -> String = #externalMacro(module: "MacroImplementation",
                                                                       type: "LocalizedMacro")
