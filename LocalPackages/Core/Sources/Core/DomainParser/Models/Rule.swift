//
//  Rule.swift
//  DomainParser
//
//  Created by Jason Akakpo on 19/07/2018.
//  Copyright © 2018 Dashlane. All rights reserved.
//
import Foundation

/// Represents a Public Suffix Rule
struct Rule {
    /// Is this rule an exception
    let exception: Bool

    /// The raw rule in the PSL format
    let source: String

    /// Labels separated rules
    let parts: [RuleLabel]

    /// Score used to sort the rules. If a URL match multiple rules, the one with the highest Score is prevailing
    let rankingScore: Int

    init(raw: Substring) {
        /// If the line starts with "!" it's an exceptional Rule
        exception = raw.starts(with: DomainParserContant.exceptionMarker)
        source = exception ? String(raw.dropFirst()) : String(raw)
        parts = source.split(separator: ".").map(RuleLabel.init)

        /// Exceptions should have a higher Rank than regular rules
        rankingScore = (exception ? 1_000 : 0) + parts.count
    }
}

extension Rule {
    /// From https://publicsuffix.org/list/
    /// A domain is said to match a rule if and only if all of the following conditions are met:
    /// - When the domain and rule are split into corresponding labels,
    ///     that the domain contains as many or more labels than the rule.
    /// - Beginning with the right-most labels of both the domain and the rule,
    ///     and continuing for all labels in the rule, one finds that for every pair,
    ///     either they are identical, or that the label from the rule is "*".
    func isMatching(hostLabels: [Substring]) -> Bool {
        let delta = hostLabels.count - parts.count

        /// The url should have at least the same number of labels than the url
        guard delta >= 0 else { return false }

        /// Drop the excedent so we have two arrays of the same size
        let trimmedHostLabels = hostLabels.dropFirst(delta)

        let zipped = zip(parts, trimmedHostLabels)
        /// Closure that check if a RuleLabel match a given string
        let matchingClosure: (RuleLabel, Substring) -> Bool = { ruleComponent, hostComponent in
            ruleComponent.isMatching(label: hostComponent)
        }

        #if swift(>=4.2)
        return zipped.allSatisfy(matchingClosure)
        #else
        let notMatchingClosure: (RuleLabel, String) -> Bool = { ruleComponent, hostComponent in
            !matchingClosure(ruleComponent, hostComponent)
        }
        return !zipped.contains(where: notMatchingClosure)
        #endif
        // return matching
    }

    /// ⚠️ Should be called only for host matching the rule
    func parse(hostLabels: [Substring]) -> ParsedHost {
        let partsCount = parts.count - (exception ? 1 : 0)
        let delta = hostLabels.count - partsCount

        let domain = delta == 0 ? nil : hostLabels.dropFirst(delta - 1).joined(separator: ".")

        let publicSuffix = hostLabels.dropFirst(delta).joined(separator: ".")
        return ParsedHost(publicSuffix: publicSuffix,
                          domain: domain)
    }
}

// MARK: - Comparable

extension Rule: Comparable {
    static func < (lhs: Rule, rhs: Rule) -> Bool {
        lhs.rankingScore < rhs.rankingScore
    }

    static func == (lhs: Rule, rhs: Rule) -> Bool {
        lhs.rankingScore == rhs.rankingScore
    }
}
