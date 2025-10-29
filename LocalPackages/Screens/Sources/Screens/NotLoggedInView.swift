//
// NotLoggedInView.swift
// Proton Pass - Created on 23/01/2024.
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
import Lottie
import Macro
import ProtonCoreLoginUIResourcesiOS
import ProtonCoreUIFoundations
import SwiftUI

public extension NotLoggedInView {
    enum Variant {
        case autoFillExtension, shareExtension, actionExtension

        var message: String {
            switch self {
            case .autoFillExtension:
                #localized("Please sign in to use Proton Pass AutoFill extension", bundle: .module)
            case .shareExtension:
                #localized("Please sign in to use Proton Pass Share extension", bundle: .module)
            case .actionExtension:
                #localized("Please sign in to use Proton Pass Action extension", bundle: .module)
            }
        }
    }
}

public struct NotLoggedInView: View {
    private let variant: Variant
    private let onCancel: () -> Void

    public init(variant: Variant, onCancel: @escaping () -> Void) {
        self.variant = variant
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack {
            LottieView(animation: .named("sign-up-create-account",
                                         bundle: ProtonCoreLoginUIResourcesiOS.spmResourcesBundle))
                .playing(loopMode: .loop)
                .frame(maxWidth: 160, maxHeight: 160)
                .padding(.bottom)

            Group {
                Text("Signed out", bundle: .module)
                    .font(.title2.bold())
                Text(variant.message)
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(PassColor.textNorm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .padding(.bottom, 100)
        .background(PassColor.backgroundNorm)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CircleButton(icon: IconProvider.cross,
                             iconColor: PassColor.interactionNormMajor2,
                             backgroundColor: PassColor.interactionNormMinor1,
                             accessibilityLabel: "Cancel",
                             action: onCancel)
            }
        }
        .navigationStackEmbeded()
    }
}
