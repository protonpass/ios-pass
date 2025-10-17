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

extension FullInviteSuggestions {
    func recentRecommandation() -> [String] {
        (groupInfos?.map {
            guard let memberCounts = $0.memberCounts else {
                return $0.name
            }
            return "\($0.name) (\(memberCounts))"
        } ?? []) + recommendations.recommendedEmails
    }

    var recentCount: Int {
        recommendations.recommendedEmails.count + (groupInfos?.count ?? 0)
    }

    func recommendations(_ selectedIndex: Int) -> [InviteRecommendationType] {
        if selectedIndex == 0 {
            let groups = groupInfos ?? [InviteRecommendationType]()
            let emails = recommendations.recommendedEmails.toInviteRecommendationTypes
            return groups + emails
        } else {
            return recommendations.planRecommendedEmails.toInviteRecommendationTypes
        }
    }
}

extension [String] {
    var toInviteRecommendationTypes: [InviteRecommendationType] {
        map { .email($0) }
    }
}

public struct InviteSuggestionsSection: View {
    @State private var selectedIndex = 0
    private let selectedRecommendations: [InviteRecommendationType]
    private let suggestions: FullInviteSuggestions
    private let isFetchingMore: Bool
    private let displayCounts: Bool
    private let onSelect: (InviteRecommendationType) -> Void
    private let onLoadMore: () -> Void

    public init(selectedRecommendations: [InviteRecommendationType],
                suggestions: FullInviteSuggestions,
                isFetchingMore: Bool,
                displayCounts: Bool,
                onSelect: @escaping (InviteRecommendationType) -> Void,
                onLoadMore: @escaping () -> Void) {
        self.selectedRecommendations = selectedRecommendations
        self.suggestions = suggestions
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

            if let planName = suggestions.recommendations.groupDisplayName ?? suggestions
                .recommendations.planInternalName {
                let recentTabTitle = #localized("Recents", bundle: .module) +
                    (displayCounts ?
                        " (\(suggestions.recentCount))" : "")
                let planTabTitle = planName +
                    (displayCounts ? " (\(suggestions.recommendations.planRecommendedEmails.count))" :
                        "")
                SegmentedPicker(selectedIndex: $selectedIndex,
                                options: [recentTabTitle, planTabTitle])
            }

            emailList(suggestions.recommendations(selectedIndex))

            if isFetchingMore {
                emailSkeleton
            }
        }
        .animation(.default, value: isFetchingMore)
    }
}

private extension InviteSuggestionsSection {
    func emailList(_ recommendations: [InviteRecommendationType]) -> some View {
        ForEach(recommendations, id: \.self) { recommendation in
            SuggestedEmailView(recommendation: recommendation,
                               isSelected: selectedRecommendations.contains(recommendation),
                               onSelect: { onSelect(recommendation) })
                .onAppear {
                    if selectedIndex == 1,
                       recommendation == suggestions.recommendations.planRecommendedEmails
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
