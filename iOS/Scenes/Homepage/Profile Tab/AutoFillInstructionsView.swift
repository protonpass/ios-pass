//
// AutoFillInstructionsView.swift
// Proton Pass - Created on 28/08/2023.
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
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct AutoFillInstructionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            realBody
        }
    }
}

private extension AutoFillInstructionsView {
    var realBody: some View {
        VStack(alignment: .leading) {
            Image(uiImage: PassIcon.autoFillOnWebPreview)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer()

            Text("Enable AutoFill")
                .font(.title3.bold())

            Text("Follow these simple steps to get the best experience:")
                .padding(.vertical, 8)

            Group {
                step(number: 1, title: #localized("Open System Settings → Passwords → Password Options"))
                step(number: 2,
                     title: #localized("Turn on AutoFill Passwords and allow filling from Proton Pass"),
                     images: [PassIcon.enableAutoFillStep2a, PassIcon.enableAutoFillStep2b])
                step(number: 3, title: #localized("Restart Proton Pass"))
            }

            Spacer()
        }
        .padding(64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .toolbar { toolbarContent }
        .background(PassColor.backgroundNorm.toColor)
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }
    }

    func step(number: Int, title: String, images: [UIImage]? = nil) -> some View {
        Label(title: {
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundStyle(PassColor.textNorm.toColor)
                    .fontWeight(.bold)
                if let images {
                    ForEach(0..<images.count, id: \.self) { index in
                        if let image = images[safeIndex: index] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
        }, icon: {
            Text(verbatim: "\(number)")
                .fontWeight(.medium)
                .padding(10)
                .background(PassColor.interactionNorm.toColor)
                .clipShape(Circle())
        })
    }
}
