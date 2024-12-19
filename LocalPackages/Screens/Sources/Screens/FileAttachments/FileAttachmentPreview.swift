//
// FileAttachmentPreview.swift
// Proton Pass - Created on 21/11/2024.
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

import DesignSystem
import ProtonCoreUIFoundations
import SwiftUI

public struct FileAttachmentPreview: View {
    @Environment(\.dismiss) private var dismiss
    @State private var sheet: Sheet?
    let url: URL
    let primaryTintColor: UIColor
    let secondaryTintColor: UIColor

    private enum Sheet: String, Identifiable {
        case save, share

        var id: String {
            rawValue
        }
    }

    public init(url: URL,
                primaryTintColor: UIColor,
                secondaryTintColor: UIColor) {
        self.url = url
        self.primaryTintColor = primaryTintColor
        self.secondaryTintColor = secondaryTintColor
    }

    public var body: some View {
        ZStack {
            PassColor.backgroundNorm.toColor
                .ignoresSafeArea()
            QuickLookPreview(url: url)
                .padding(.top, 8)
                .ignoresSafeArea(edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .tint(primaryTintColor.toColor)
        .toolbar { toolbarContent }
        .navigationBarTitleDisplayMode(.inline)
        .navigationStackEmbeded()
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .save:
                ExportDocumentView(url: url)
            case .share:
                ActivityView(items: [url])
            }
        }
    }
}

private extension FileAttachmentPreview {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: primaryTintColor,
                         backgroundColor: secondaryTintColor,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .principal) {
            Text(verbatim: url.lastPathComponent)
                .lineLimit(1)
                .foregroundStyle(PassColor.textNorm.toColor)
                .fontWeight(.medium)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu(content: {
                LabelButton(title: "Save",
                            icon: IconProvider.arrowDownCircle,
                            action: { sheet = .save })
                LabelButton(title: "Share",
                            icon: IconProvider.arrowUpFromSquare,
                            action: { sheet = .share })
            }, label: {
                CircleButton(icon: IconProvider.threeDotsVertical,
                             iconColor: primaryTintColor,
                             backgroundColor: secondaryTintColor)
            })
        }
    }
}
