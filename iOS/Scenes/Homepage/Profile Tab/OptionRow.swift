//
// OptionRow.swift
// Proton Pass - Created on 31/03/2023.
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

import SwiftUI
import UIComponents

struct OptionRow<Content: View, LeadingView: View, TrailingView: View>: View {
    var title: String?
    let content: Content
    var leading: LeadingView
    var trailing: TrailingView
    let action: (() -> Void)?

    init(action: (() -> Void)? = nil,
         title: String? = nil,
         @ViewBuilder content: () -> Content,
         @ViewBuilder leading: (() -> LeadingView) = { EmptyView() },
         @ViewBuilder trailing: (() -> TrailingView) = { EmptyView() }) {
        self.title = title
        self.content = content()
        self.leading = leading()
        self.trailing = trailing()
        self.action = action
    }

    var body: some View {
        if let action {
            Button(action: action) {
                realBody
            }
            .buttonStyle(.plain)
            .padding(kItemDetailSectionPadding)
        } else {
            realBody
                .padding(kItemDetailSectionPadding)
        }
    }

    private var realBody: some View {
        HStack {
            leading

            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title)
                        .sectionTitleText()
                }
                content
            }

            Spacer()

            trailing
        }
        .contentShape(Rectangle())
    }
}
