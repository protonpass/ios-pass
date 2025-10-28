//
// AliasSyncExplanationView.swift
// Proton Pass - Created on 05/08/2024.
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
import ProtonCoreUIFoundations
import SwiftUI

public struct AliasSyncExplanationView: View {
    let missingAliases: Int
    let dimissAction: (() -> Void)?
    let enableAliasSyncAction: () -> Void

    public init(missingAliases: Int,
                dimissAction: (() -> Void)? = nil,
                enableAliasSyncAction: @escaping () -> Void) {
        self.missingAliases = missingAliases
        self.dimissAction = dimissAction
        self.enableAliasSyncAction = enableAliasSyncAction
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Text("Enable SimpleLogin sync", bundle: .module)
                    .fontWeight(.bold)
                    .foregroundStyle(PassColor.textNorm)
                    .padding(.bottom, 8)
                // swiftlint:disable:next line_length
                Text("We detected that you have \(missingAliases) aliases that are present in SimpleLogin but missing in Proton Pass. Would you like to import them?",
                     bundle: .module)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PassColor.textNorm)
                    .padding(.bottom, 8)
                CapsuleTextButton(title: #localized("Sync aliases", bundle: .module),
                                  titleColor: PassColor.interactionNormMinor1,
                                  backgroundColor: PassColor.interactionNormMajor2,
                                  action: enableAliasSyncAction)
            }
            .padding(24)

            if let dimissAction {
                Button(action: dimissAction) {
                    Image(uiImage: IconProvider.cross)
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(16)
                        .foregroundStyle(PassColor.textWeak)
                }
            }
        }
        .roundedEditableSection()
    }
}
