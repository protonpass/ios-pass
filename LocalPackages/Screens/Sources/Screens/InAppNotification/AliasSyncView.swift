//
// AliasSyncView.swift
// Proton Pass - Created on 23/01/2025.
// Copyright (c) 2025 Proton Technologies AG
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

public struct AliasSyncView: View {
    private let count: Int
    private let onDismiss: () -> Void
    private let onSync: () -> Void

    public init(count: Int,
                onDismiss: @escaping () -> Void,
                onSync: @escaping () -> Void) {
        self.count = count
        self.onDismiss = onDismiss
        self.onSync = onSync
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            PassColor.backgroundWeak
                .ignoresSafeArea()

            VStack {
                Image(uiImage: PassIcon.aliasSync)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 80)
                    .padding(.top, 48)

                Spacer()

                Text("Sync your aliases from SimpleLogin", bundle: .module)
                    .foregroundStyle(PassColor.textNorm)
                    .font(.title.bold())

                Text(#localized("%lld aliases present in SimpleLogin but missing in Proton Pass.", bundle: .module,
                                count))
                    .foregroundStyle(PassColor.textWeak)
                    .padding(.vertical, 8)

                Text("Once synced, deleting aliases in Pass will also delete them in SimpleLogin.",
                     bundle: .module)
                    .padding()
                    .foregroundStyle(PassColor.noteInteractionNormMajor2)
                    .background(PassColor.noteInteractionNormMinor1)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                CapsuleTextButton(title: #localized("Sync aliases", bundle: .module),
                                  titleColor: PassColor.interactionNormMinor1,
                                  backgroundColor: PassColor.interactionNormMajor2,
                                  height: 48,
                                  action: onSync)
            }
            .multilineTextAlignment(.center)
            .padding([.horizontal, .bottom])
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(PassColor.textNorm)
            }
            .buttonStyle(.plain)
            .padding()
        }
    }
}
