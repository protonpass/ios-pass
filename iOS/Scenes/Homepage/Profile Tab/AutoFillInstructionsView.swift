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

import Core
import Factory
import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct AutoFillInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    private var theme = resolve(\SharedToolingContainer.theme)

    var body: some View {
        NavigationView {
            realBody
        }
        .navigationViewStyle(.stack)
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
                step(number: 1, title: "Open System Settings".localized)
                step(number: 2, title: "Select Passwords".localized)
                step(number: 3, title: "Select Password Options".localized)
                step(number: 4,
                     title: "Turn on AutoFill Passwords".localized,
                     image: PassIcon.enableAutoFillStep4)
                step(number: 5,
                     title: "Allow filling from Proton Pass".localized,
                     image: PassIcon.enableAutoFillStep5)
                step(number: 6, title: "Restart Proton Pass".localized)
            }

            Spacer()
        }
        .padding(64)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .toolbar { toolbarContent }
        .background(PassColor.backgroundNorm.toColor)
        .theme(theme)
    }

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         action: dismiss.callAsFunction)
        }
    }

    func step(number: Int, title: String, image: UIImage? = nil) -> some View {
        Label(title: {
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(PassColor.textNorm.toColor)
                    .fontWeight(.bold)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
        }, icon: {
            Text("\(number)")
                .fontWeight(.medium)
                .padding(10)
                .background(PassColor.interactionNorm.toColor)
                .clipShape(Circle())
        })
    }
}
