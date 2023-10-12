//
// CopyableMacro.swift
// Proton Pass - Created on 12/10/2023.
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

import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum CopyableDiagnostic: DiagnosticMessage {
    case notAStruct
    case propertyTypeProblem(PatternBindingListSyntax.Element)

    var severity: DiagnosticSeverity {
        switch self {
        case .notAStruct: .error
        case .propertyTypeProblem: .warning
        }
    }

    var message: String {
        switch self {
        case .notAStruct:
            "'@Copyable' can only be applied to a 'struct'"
        case let .propertyTypeProblem(binding):
            "Type error for property '\(binding.pattern)': \(binding)"
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .notAStruct:
            .init(domain: "ModifiedCopyMacros", id: "notAStruct")
        case let .propertyTypeProblem(binding):
            .init(domain: "ModifiedCopyMacros", id: "propertyTypeProblem(\(binding.pattern))")
        }
    }
}

public struct CopyableMacro: MemberMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let structDeclSyntax = declaration as? StructDeclSyntax else {
            let diagnostic = Diagnostic(node: node, message: CopyableDiagnostic.notAStruct)
            context.diagnose(diagnostic)
            return []
        }
        let variables = structDeclSyntax.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }

        let bindings = variables.flatMap(\.bindings).filter { accessorIsAllowed($0.accessorBlock) }

        return bindings.compactMap { binding in
            let propertyName = binding.pattern
            guard let typeName = binding.typeAnnotation?.type else {
                let diagnostic = Diagnostic(node: node,
                                            message: CopyableDiagnostic.propertyTypeProblem(binding))
                context.diagnose(diagnostic)
                return nil
            }

            return """
            /// Returns a copy of the caller whose value for `\(propertyName)` is different.
            func copy(\(propertyName): \(typeName.trimmed)) -> Self {
                .init(\(raw: bindings.map { "\($0.pattern): \($0.pattern)" }.joined(separator: ", ")))
            }
            """
        }
    }

    private static func accessorIsAllowed(_ accessorsBlock: AccessorBlockSyntax?) -> Bool {
        guard let accessorsBlock else { return true }
        switch accessorsBlock.accessors {
        case let .accessors(accessorDeclListSyntax):
            return !accessorDeclListSyntax.contains(where: {
                $0.accessorSpecifier.text == "get" || $0.accessorSpecifier.text == "set"
            })
        case .getter:
            return false
        }
    }
}
