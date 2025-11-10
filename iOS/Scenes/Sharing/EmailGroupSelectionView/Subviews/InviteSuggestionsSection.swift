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

            emailList()

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
            EnumSegmentedPicker(selection: $viewModel.displayType,
                                options: [#localized("Suggestions"), organizationTitle])
        }
    }
}

private extension InviteSuggestionsSection {
    func emailList() -> some View {
        ForEach(viewModel.suggestions ?? []) { recommendation in
            SuggestedEmailView(recommendation: recommendation,
                               isSelected: viewModel.selectedRecommendations.contains(recommendation)) {
                viewModel.handleSelection(recommendation)
            }.onAppear {
                if viewModel.displayType == .organisation,
                   recommendation == viewModel.suggestions?.last {
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

struct EnumSegmentedPicker<Selection>: View where Selection: RawRepresentable, Selection.RawValue == Int,
    Selection: Hashable {
    @Binding private var selection: Selection
    private let options: [String]
    private let highlightTextColor: Color
    private let mainColor: Color
    private let backgroundColor: Color

    init(selection: Binding<Selection>,
         options: [String],
         highlightTextColor: Color = PassColor.textNorm,
         mainColor: Color = PassColor.interactionNormMajor1,
         backgroundColor: Color = PassColor.interactionNormMinor1) {
        _selection = selection
        self.options = options
        self.mainColor = mainColor
        self.backgroundColor = backgroundColor
        self.highlightTextColor = highlightTextColor
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let thumbWidth = proxy.size.width / CGFloat(options.count)
                mainColor
                    .clipShape(Capsule())
                    .frame(width: thumbWidth)
                    .offset(x: thumbWidth * CGFloat(selection.rawValue))
                    .animation(.default, value: selection.rawValue)
            }

            HStack {
                ForEach(Array(options.enumerated()), id: \.element) { index, option in
                    Button(action: {
                        if let currentSelection = Selection(rawValue: index) {
                            selection = currentSelection
                        }
                    }, label: {
                        Text(option)
                            .font(.body.weight(.medium))
                            .foregroundStyle(index == selection.rawValue ?
                                highlightTextColor : PassColor.textNorm)
                            .frame(maxWidth: .infinity, alignment: .center)
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(5)
        .background(backgroundColor)
        .clipShape(Capsule())
        .frame(height: DesignConstant.defaultPickerHeight)
    }
}
