//
// NoCameraPermissionView.swift
// Proton Pass - Created on 02/03/2023.
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
import Factory
import Macro
import ProtonCoreUIFoundations
import SwiftUI

struct NoCameraPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    let onOpenSettings: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PassColor.backgroundNorm.toColor
                    .ignoresSafeArea()

                VStack(spacing: 44) {
                    Text("Camera permission required for this feature to be available")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(PassColor.textNorm.toColor)

                    if !Bundle.main.bundlePath.hasSuffix(".appex") {
                        CapsuleTextButton(title: #localized("Open Settings"),
                                          titleColor: PassColor.textInvert,
                                          backgroundColor: PassColor.interactionNormMajor1,
                                          action: onOpenSettings)
                            .frame(width: 250)
                    } else {
                        Text("Please allow camera access in Settings")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(PassColor.textNorm.toColor)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CircleButton(icon: IconProvider.cross,
                                 iconColor: PassColor.interactionNormMajor2,
                                 backgroundColor: PassColor.interactionNormMinor1,
                                 accessibilityLabel: "Close",
                                 action: dismiss.callAsFunction)
                }
            }
        }
    }
}
