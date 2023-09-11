//
//  RulesParser.swift
//  DomainParser
//
//  Created by Jason Akakpo on 04/09/2018.
//  Copyright © 2018 Dashlane. All rights reserved.
//

import Foundation

final class RulesParser {
    var exceptions = [Rule]()
    var wildcardRules = [Rule]()
    /// Set of suffixes
    var basicRules = Set<String>()

    /// Parse the Data to extract an array of Rules. The array is sorted by importance.
    func parse(raw: Data) throws -> ParsedRules {
        guard let rulesText = String(data: raw, encoding: .utf8) else {
            throw DomainParserError.parsingError(details: nil)
        }
        rulesText
            .split(separator: "\n")
            .forEach(parseRule)
        return ParsedRules(exceptions: exceptions,
                           wildcardRules: wildcardRules,
                           basicRules: basicRules)
    }

    private func parseRule(line: Substring) {
        if line.contains("*") {
            wildcardRules.append(Rule(raw: line))
        } else if line.starts(with: "!") {
            exceptions.append(Rule(raw: line))
        } else {
            basicRules.insert(String(line))
        }
    }
}

private extension String {
    /// A line starting by "//" is a comment and should be ignored
    var isComment: Bool {
        starts(with: DomainParserContant.commentMarker)
    }
}
