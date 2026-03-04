//
// NoVaultsView.swift
// Proton Pass - Created on 03/03/2026.
// Copyright (c) 2026 Proton Technologies AG
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

public struct NoVaultsView: View {
    let canCreate: Bool
    let onCreate: () -> Void

    public init(canCreate: Bool, onCreate: @escaping () -> Void) {
        self.canCreate = canCreate
        self.onCreate = onCreate
    }

    public var body: some View {
        VStack {
            PassIcon.noVaults
                .scaledToFit()
                .frame(maxWidth: 124)

            Text("You don't have any vaults.")
                .font(.title3.bold())
                .foregroundStyle(PassColor.textNorm)

            if canCreate {
                CapsuleTextButton(title: #localized("Create new vault", bundle: .module),
                                  titleColor: PassColor.interactionNormMajor2,
                                  backgroundColor: PassColor.interactionNormMinor1,
                                  maxWidth: nil,
                                  action: onCreate)
            } else {
                Label("Please contact your administrator.", systemImage: "questionmark.circle")
                    .foregroundStyle(PassColor.textWeak)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .overlay(Capsule().strokeBorder(ColorProvider.InteractionWeak, lineWidth: 1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
