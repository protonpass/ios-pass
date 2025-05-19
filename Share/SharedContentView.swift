//
// SharedContentView.swift
// Proton Pass - Created on 22/01/2024.
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

import DesignSystem
import Entities
import FactoryKit
import ProtonCoreUIFoundations
import SwiftUI

struct SharedContentView: View {
    let content: SharedContent
    let onCreate: (SharedItemType) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            VStack(spacing: DesignConstant.sectionPadding) {
                Text(content.text)
                    .foregroundStyle(PassColor.textWeak.toColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DesignConstant.sectionPadding)
                    .roundedEditableSection()

                Spacer()

                ForEach(SharedItemType.allCases, id: \.self) { type in
                    CapsuleLabelButton(icon: type.contentType.regularIcon,
                                       title: type.contentType.createItemTitle,
                                       titleColor: type.contentType.normMajor2Color,
                                       backgroundColor: type.contentType.normMinor1Color,
                                       height: 52,
                                       leadingIcon: true,
                                       action: { onCreate(type) })
                }
            }
            .padding()
        }
        .toolbar { toolbarContent }
        .navigationTitle("Create")
        .navigationStackEmbeded()
    }
}

private extension SharedContentView {
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: onDismiss)
        }
    }
}

private extension SharedContent {
    var text: String {
        switch self {
        case let .url(url):
            url.absoluteString
        case let .text(text):
            text
        case let .textWithUrl(text, _):
            text
        default:
            ""
        }
    }
}

private extension SharedItemType {
    var contentType: ItemContentType {
        switch self {
        case .note: .note
        case .login: .login
        }
    }
}
