//
// InviteSuggestionsSection.swift
// Proton Pass - Created on 15/12/2023.
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

import DesignSystem
import Entities
import Macro
import SwiftUI

public struct FullInviteSuggestions {
    let recommendations: InviteRecommendations
    let groupInfos: [GroupInfo]?

    public init(recommendations: InviteRecommendations, groupInfos: [GroupInfo]?) {
        self.recommendations = recommendations
        self.groupInfos = groupInfos
    }

    func recentRecommandation() -> [String] {
        (groupInfos?.map { "\($0.group.name) (\($0.memberCounts))" } ?? []) + recommendations.recommendedEmails
    }
}

public enum InviteRecommendationType: Sendable, Equatable, Hashable, Identifiable {
    case email(String)
    case group(GroupInfo)

    public var currentEmail: String? {
        switch self {
        case let .email(email):
            email
        case let .group(groupInfo):
            groupInfo.group.address?.email
        }
    }

    public var name: String {
        switch self {
        case let .email(email):
            email
        case let .group(groupInfo):
            groupInfo.group.name + " (\(groupInfo.memberCounts))"
        }
    }

    public var id: Self { self }
}

public extension [InviteRecommendationType] {
    var emails: [String] {
        compactMap(\.currentEmail)
    }
}

public extension [String] {
    var toInviteRecommendationTypes: [InviteRecommendationType] {
        map { .email($0) }
    }
}

public extension [GroupInfo]? {
    var toRecommendationTypes: [InviteRecommendationType]? {
        self?.map { .group($0) }
    }
}

public struct InviteSuggestionsSection: View {
    @State private var selectedIndex = 0
    private let selectedRecommendations: [InviteRecommendationType]
    private let fullInviteSuggestions: FullInviteSuggestions
    private let isFetchingMore: Bool
    private let displayCounts: Bool
    private let onSelect: (InviteRecommendationType) -> Void
    private let onLoadMore: () -> Void

    public init(selectedRecommendations: [InviteRecommendationType],
                fullInviteSuggestions: FullInviteSuggestions,
                isFetchingMore: Bool,
                displayCounts: Bool,
                onSelect: @escaping (InviteRecommendationType) -> Void,
                onLoadMore: @escaping () -> Void) {
        self.selectedRecommendations = selectedRecommendations
        self.fullInviteSuggestions = fullInviteSuggestions
        self.isFetchingMore = isFetchingMore
        self.displayCounts = displayCounts
        self.onSelect = onSelect
        self.onLoadMore = onLoadMore
    }

    public var body: some View {
        LazyVStack {
            Text("Suggestions", bundle: .module)
                .foregroundStyle(PassColor.textWeak.toColor)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let planName = fullInviteSuggestions.recommendations.groupDisplayName ?? fullInviteSuggestions
                .recommendations.planInternalName {
                let recentTabTitle = #localized("Recents", bundle: .module) +
                    (displayCounts ?
                        " (\(fullInviteSuggestions.recommendations.recommendedEmails.count + (fullInviteSuggestions.groupInfos?.count ?? 0)))" :
                        "")
                let planTabTitle = planName +
                    (displayCounts ? " (\(fullInviteSuggestions.recommendations.planRecommendedEmails.count))" :
                        "")
                SegmentedPicker(selectedIndex: $selectedIndex,
                                options: [recentTabTitle, planTabTitle])
            }

            emailList(recommendations(selectedIndex))

            if isFetchingMore {
                emailSkeleton
            }
        }
        .animation(.default, value: isFetchingMore)
    }

    func recommendations(_ selectedIndex: Int) -> [InviteRecommendationType] {
        if selectedIndex == 0 {
            let groups = fullInviteSuggestions.groupInfos.toRecommendationTypes ?? [InviteRecommendationType]()
            let emails = fullInviteSuggestions.recommendations.recommendedEmails.toInviteRecommendationTypes
            return groups + emails
//            (fullInviteSuggestions.groupInfos?.toInviteRecommendationTypes ?? []) +
//            fullInviteSuggestions.recommendations.recommendedEmails.toInviteRecommendationTypes
        } else {
            return fullInviteSuggestions.recommendations.planRecommendedEmails.toInviteRecommendationTypes
        }
//
//        fullInviteSuggestions.recentRecommandation() : fullInviteSuggestions.recommendations
//        .planRecommendedEmails
//
//        (groupInfos?.map { "\($0.group.name) (\($0.memberCounts))" } ?? []) + recommendations.recommendedEmails
    }
}

private extension InviteSuggestionsSection {
    func emailList(_ recommendations: [InviteRecommendationType]) -> some View {
        ForEach(recommendations, id: \.self) { recommendation in
            SuggestedEmailView(email: recommendation.name,
                               isSelected: selectedRecommendations.contains(recommendation),
                               onSelect: { onSelect(recommendation) })
                .onAppear {
                    if selectedIndex == 1,
                       recommendation == fullInviteSuggestions.recommendations.planRecommendedEmails
                       .toInviteRecommendationTypes.last {
                        onLoadMore()
                    }
                }
        }
    }

    var emailSkeleton: some View {
        HStack {
            SkeletonBlock()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer()

            SkeletonBlock()
                .frame(height: 24)
                .clipShape(Capsule())

            Spacer()

            SkeletonBlock()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .shimmering()
    }
}
