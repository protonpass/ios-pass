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
import Screens
import SwiftUI

struct InviteSuggestionsSection: View {
    @EnvironmentObject private var viewModel: EmailGroupSelectionViewModel

    var body: some View {
        LazyVStack {
            title

            suggestionPicker

            emailList

            if viewModel.isFetchingMore {
                emailSkeleton
            }
        }
        .animation(.default, value: viewModel.isFetchingMore)
    }

    var title: some View {
        Text("Suggestions")
            .foregroundStyle(PassColor.textWeak)
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var suggestionPicker: some View {
        if let organizationTitle = viewModel.organizationTitle {
            SegmentedPicker(selection: $viewModel.displayType,
                            options: [
                                .init(value: .suggestion, title: #localized("Suggestions")),
                                .init(value: .organisation, title: organizationTitle)
                            ])
        }
    }
}

private extension InviteSuggestionsSection {
    var emailList: some View {
        ForEach(viewModel.suggestions) { recommendation in
            SuggestedEmailView(recommendation: recommendation,
                               isSelected: viewModel.selectedRecommendations.contains(recommendation)) {
                viewModel.handleSelection(recommendation)
            }.onAppear {
                if viewModel.displayType == .organisation,
                   recommendation == viewModel.suggestions.last {
                    viewModel.loadMore()
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
