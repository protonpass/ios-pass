//
// ExtraPasswordSheet.swift
// Proton Pass - Created on 05/06/2024.
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
import Macro
import SwiftUI

struct ExtraPasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .padding(4)
                    .frame(width: 30, height: 30)
                    .foregroundStyle(PassColor.textWeak)
                    .buttonEmbeded(action: dismiss.callAsFunction)
            }

            PassIcon.extraPassword
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)

            Text("Extra password")
                .font(.title.bold())
                .foregroundStyle(PassColor.textNorm)

            Text("Protect Proton Pass with an extra password.")
                .foregroundStyle(PassColor.textWeak)
                .padding(.vertical, 16)
                .multilineTextAlignment(.center)

            CapsuleTextButton(title: #localized("Set extra password"),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNorm,
                              height: 48,
                              action: { dismiss(); onContinue() })
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(PassColor.backgroundNorm)
    }
}
