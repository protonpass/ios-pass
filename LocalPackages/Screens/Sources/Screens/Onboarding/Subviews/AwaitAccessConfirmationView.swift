//
// AwaitAccessConfirmationView.swift
// Proton Pass - Created on 19/10/2023.
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
//

import DesignSystem
import Lottie
import Macro
import ProtonCoreLoginUIResourcesiOS
import SwiftUI

public struct AwaitAccessConfirmationView: View {
    let onLearnMore: () -> Void

    public init(onLearnMore: @escaping () -> Void) {
        self.onLearnMore = onLearnMore
    }

    public var body: some View {
        VStack(alignment: .center) {
            Spacer()

            LottieView(animation: .named("sign-up-create-account",
                                         bundle: ProtonCoreLoginUIResourcesiOS.spmResourcesBundle))
                .playing(loopMode: .loop)
                .frame(maxWidth: 160, maxHeight: 160)

            Text("Pending access to the shared data", bundle: .module)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(PassColor.textNorm)
                .padding(.top, 32)

            Text("For security reasons, your access needs to be confirmed", bundle: .module)
                .foregroundStyle(PassColor.textWeak)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            CapsuleTextButton(title: #localized("Learn more about Pass", bundle: .module),
                              titleColor: PassColor.textInvert,
                              backgroundColor: PassColor.interactionNorm,
                              height: 52,
                              action: onLearnMore)
                .padding(.top, 44)

            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassColor.backgroundNorm)
    }
}
