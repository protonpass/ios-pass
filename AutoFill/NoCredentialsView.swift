//
// NoCredentialsView.swift
// Proton Pass - Created on 07/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCoreUIFoundations
import SwiftUI
import UIComponents

struct NoCredentialsView: View {
    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Text("You currently have no login items")
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(uiColor: PassColor.textNorm))
                    .padding()

                VStack {
                    Spacer()
                    CreateLoginButton(onCreate: onCreate)
                }
                .padding()
            }
            .background(Color(uiColor: PassColor.backgroundNorm))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 action: onCancel)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct CreateLoginButton: View {
    let onCreate: () -> Void

    var body: some View {
        CapsuleTextButton(title: "Create login".localized,
                          titleColor: PassColor.loginInteractionNormMajor2,
                          backgroundColor: PassColor.loginInteractionNormMinor1,
                          height: 52,
                          action: onCreate)
    }
}
