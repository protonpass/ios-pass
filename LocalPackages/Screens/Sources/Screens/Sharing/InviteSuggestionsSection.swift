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

public struct InviteSuggestionsSection: View {
    @State private var selectedIndex = 0
    private let selectedEmails: [String]
    private let recommendations: InviteRecommendations
    private let isFetchingMore: Bool
    private let displayCounts: Bool
    private let onSelect: (String) -> Void
    private let onLoadMore: () -> Void

    public init(selectedEmails: [String],
                recommendations: InviteRecommendations,
                isFetchingMore: Bool,
                displayCounts: Bool,
                onSelect: @escaping (String) -> Void,
                onLoadMore: @escaping () -> Void) {
        self.selectedEmails = selectedEmails
        self.recommendations = recommendations
        self.isFetchingMore = isFetchingMore
        self.displayCounts = displayCounts
        self.onSelect = onSelect
        self.onLoadMore = onLoadMore
    }

    public var body: some View {
        LazyVStack {
            Text("Suggestions", bundle: .module)
                .foregroundStyle(PassColor.textWeak)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let planName = recommendations.groupDisplayName ?? recommendations.planInternalName {
                let recentTabTitle = #localized("Recents", bundle: .module) +
                    (displayCounts ? " (\(recommendations.recommendedEmails.count))" : "")
                let planTabTitle = planName +
                    (displayCounts ? " (\(recommendations.planRecommendedEmails.count))" : "")
                SegmentedPicker(selectedIndex: $selectedIndex,
                                options: [recentTabTitle, planTabTitle])
            }

            emailList(selectedIndex == 0 ?
                recommendations.recommendedEmails : recommendations.planRecommendedEmails)

            if isFetchingMore {
                emailSkeleton
            }
        }
        .animation(.default, value: isFetchingMore)
    }
}

private extension InviteSuggestionsSection {
    func emailList(_ emails: [String]) -> some View {
        ForEach(emails, id: \.self) { email in
            SuggestedEmailView(email: email,
                               isSelected: selectedEmails.contains(email),
                               onSelect: { onSelect(email) })
                .onAppear {
                    if selectedIndex == 1, email == recommendations.planRecommendedEmails.last {
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
