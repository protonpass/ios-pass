//
// AliasContactsEmptyView.swift
// Proton Pass - Created on 05/11/2024.
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

struct AliasContactsEmptyView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            Image(uiImage: PassIcon.stamp)

            VStack(spacing: DesignConstant.sectionPadding) {
                Text("Alias contacts")
                    .font(.title2.bold())
                    .foregroundStyle(PassColor.textNorm)

                // swiftlint:disable:next line_length
                Text("To keep your personal email address hidden, you can create an alias contact that masks your address.")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .foregroundStyle(PassColor.textNorm)
            }
            .padding(.horizontal, 40)

            CapsuleTextButton(title: #localized("Learn more"),
                              titleColor: PassColor.aliasInteractionNormMajor2,
                              backgroundColor: PassColor.aliasInteractionNormMinor1,
                              maxWidth: nil,
                              action: action)
            Spacer()
        }
    }
}
