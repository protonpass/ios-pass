//
// OnboardingFirstLoginCreatedStep.swift
// Proton Pass - Created on 03/04/2025.
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
//

import DesignSystem
import SwiftUI

struct OnboardingFirstLoginCreatedStep: View {
    let payload: OnboardFirstLoginPayload

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Spacer()
            sparkledLogin
            Text("First login created")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(PassColor.textNorm)
                .padding(.top, 50)
                .padding(.bottom, DesignConstant.sectionPadding)
            // swiftlint:disable:next line_length
            Text("You are ready to get the most out of Proton Pass: the magic of AutoFill, the privacy of Aliases and much more.")
                .font(.title3)
                .foregroundStyle(PassColor.textWeak)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .multilineTextAlignment(.center)
        .padding(40)
    }
}

private extension OnboardingFirstLoginCreatedStep {
    var sparkledLogin: some View {
        ZStack(alignment: .trailing) {
            Image(uiImage: PassIcon.onboardLoginCreatedSparkle)
                .resizable()
                .scaledToFit()
                .frame(width: 67)
                .padding(.trailing, 40)
                .padding(.top, -75)
            login
        }
    }

    var login: some View {
        HStack {
            KnownServiceThumbnail(service: payload.service, height: 40)
            VStack(alignment: .leading) {
                Text(payload.title)
                    .foregroundStyle(PassColor.textNorm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(payload.emailOrUsername)
                    .foregroundStyle(PassColor.textWeak)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignConstant.sectionPadding)
        .roundedDetailSection(backgroundColor: PassColor.inputBackgroundNorm)
        .padding(.horizontal)
    }
}
