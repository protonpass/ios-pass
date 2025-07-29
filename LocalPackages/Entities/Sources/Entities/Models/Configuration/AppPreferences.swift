//
// AppPreferences.swift
// Proton Pass - Created on 29/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Foundation

/// Application-wide preferences
public struct AppPreferences: Codable, Equatable, Sendable {
    /// The user is onboarded or not
    public var onboarded: Bool

    /// The time of the next telemetry event batch
    public var telemetryThreshold: TimeInterval?

    /// Number of created items from this device. Used to ask for review when appropriate.
    public var createdItemsCount: Int

    /// Whether to show or not custom domain explanation when viewing monitored aliases
    public var dismissedCustomDomainExplanation: Bool

    public var hasVisitedContactPage: Bool

    public var dismissedFileAttachmentsBanner: Bool

    public init(onboarded: Bool,
                telemetryThreshold: TimeInterval?,
                createdItemsCount: Int,
                dismissedCustomDomainExplanation: Bool,
                hasVisitedContactPage: Bool,
                dismissedFileAttachmentsBanner: Bool) {
        self.onboarded = onboarded
        self.telemetryThreshold = telemetryThreshold
        self.createdItemsCount = createdItemsCount
        self.dismissedCustomDomainExplanation = dismissedCustomDomainExplanation
        self.hasVisitedContactPage = hasVisitedContactPage
        self.dismissedFileAttachmentsBanner = dismissedFileAttachmentsBanner
    }
}

private extension AppPreferences {
    enum Default {
        static let onboarded = false
        static let telemetryThreshold: TimeInterval? = nil
        static let createdItemsCount = 0
        static let dismissedCustomDomainExplanation = false
        static let hasVisitedContactPage = false
        static let dismissedFileAttachmentsBanner = false
    }

    enum CodingKeys: String, CodingKey {
        case onboarded
        case telemetryThreshold
        case createdItemsCount
        case dismissedCustomDomainExplanation
        case hasVisitedContactPage
        case dismissedFileAttachmentsBanner
    }
}

public extension AppPreferences {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let onboarded = try container.decodeIfPresent(Bool.self, forKey: .onboarded)
        let telemetryThreshold = try container.decodeIfPresent(TimeInterval.self,
                                                               forKey: .telemetryThreshold)
        let createdItemsCount = try container.decodeIfPresent(Int.self, forKey: .createdItemsCount)
        let dismissedCustomDomainExplanation =
            try container.decodeIfPresent(Bool.self, forKey: .dismissedCustomDomainExplanation)

        let hasVisitedContactPage = try container.decodeIfPresent(Bool.self,
                                                                  forKey: .hasVisitedContactPage)
        let dismissedFileAttachmentsBanner =
            try container.decodeIfPresent(Bool.self, forKey: .dismissedFileAttachmentsBanner)
        self.init(onboarded: onboarded ?? Default.onboarded,
                  telemetryThreshold: telemetryThreshold ?? Default.telemetryThreshold,
                  createdItemsCount: createdItemsCount ?? Default.createdItemsCount,
                  dismissedCustomDomainExplanation: dismissedCustomDomainExplanation ?? Default
                      .dismissedCustomDomainExplanation,
                  hasVisitedContactPage: hasVisitedContactPage ?? Default.hasVisitedContactPage,
                  dismissedFileAttachmentsBanner: dismissedFileAttachmentsBanner ?? Default
                      .dismissedFileAttachmentsBanner)
    }
}

extension AppPreferences: Defaultable {
    public static var `default`: Self {
        .init(onboarded: Default.onboarded,
              telemetryThreshold: Default.telemetryThreshold,
              createdItemsCount: Default.createdItemsCount,
              dismissedCustomDomainExplanation: Default.dismissedCustomDomainExplanation,
              hasVisitedContactPage: Default.hasVisitedContactPage,
              dismissedFileAttachmentsBanner: Default.dismissedFileAttachmentsBanner)
    }
}
