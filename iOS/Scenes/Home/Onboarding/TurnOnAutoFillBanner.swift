//
// TurnOnAutoFillBanner.swift
// Proton Pass - Created on 09/12/2022.
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

import ProtonCore_UIFoundations
import SwiftUI
import UIComponents

struct TurnOnAutoFillBanner: View {
    let onAction: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Log in to apps instantly ›")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 4)

                Text("Turn on AutoFill to let Proton Pass automatically enter your login details for you.")
                    .font(.caption)
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(keyboard)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Image(uiImage: IconProvider.crossCircleFilled)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.white)
                .padding([.top, .trailing], 8)
                .onTapGesture(perform: onCancel)
        }
    }

    private var gradient: some View {
        Image(uiImage: PassIcon.turnOnAutoFillBannerGradient)
            .resizable()
            .scaledToFill()
            .onTapGesture(perform: onAction)
    }

    private var keyboard: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
                Image(uiImage: PassIcon.turnOnAutoFillBannerKeyboard)
                    .resizable()
                    .frame(width: proxy.size.width / 2)
                    .rotationEffect(.degrees(-30))
                    .offset(x: proxy.size.width / 8, y: proxy.size.height / 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
