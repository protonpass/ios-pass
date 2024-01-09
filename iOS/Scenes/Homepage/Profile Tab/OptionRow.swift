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

import DesignSystem
import SwiftUI

enum OptionRowHeight {
    case compact, short, medium, tall

    var value: CGFloat {
        switch self {
        case .compact:
            44
        case .short:
            56
        case .medium:
            72
        case .tall:
            76
        }
    }
}

struct OptionRow<Content: View, LeadingView: View, TrailingView: View>: View {
    let action: (() -> Void)?
    let title: String?
    let height: OptionRowHeight
    let horizontalPadding: CGFloat
    let content: Content
    let leading: LeadingView
    let trailing: TrailingView

    init(action: (() -> Void)? = nil,
         title: String? = nil,
         height: OptionRowHeight = .short,
         horizontalPadding: CGFloat = DesignConstant.sectionPadding,
         @ViewBuilder content: () -> Content,
         @ViewBuilder leading: (() -> LeadingView) = { EmptyView() },
         @ViewBuilder trailing: (() -> TrailingView) = { EmptyView() }) {
        self.action = action
        self.title = title
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.content = content()
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    realBody
                }
                .buttonStyle(.plain)
            } else {
                realBody
            }
        }
        .padding(.horizontal, horizontalPadding)
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
        .frame(height: height.value)
    }
}

struct TextOptionRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        OptionRow(action: action,
                  content: {
                      Text(title)
                          .foregroundColor(Color(uiColor: PassColor.textNorm))
                  },
                  trailing: { ChevronRight() })
    }
}

struct SelectableOptionRow<Content: View>: View {
    let action: () -> Void
    let height: OptionRowHeight
    @ViewBuilder let content: () -> Content
    let isSelected: Bool

    var body: some View {
        OptionRow(action: action,
                  height: height,
                  horizontalPadding: 0,
                  content: { content() },
                  trailing: {
                      if isSelected {
                          Label(title: { Text(verbatim: "") },
                                icon: { Image(systemName: "checkmark") })
                              .foregroundColor(Color(uiColor: PassColor.interactionNorm))
                      }
                  })
    }
}

struct ChevronRight: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .resizable()
            .scaledToFit()
            .frame(height: 12)
            .foregroundColor(Color(uiColor: PassColor.textHint))
    }
}
