//
// FullScreenView.swift
// Proton Pass - Created on 18/11/2022.
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

import DesignSystem
import FactoryKit
import ProtonCoreUIFoundations
import Screens
import SwiftUI

enum FullScreenData: Sendable {
    case password(String)
    case text(String)

    var text: String {
        switch self {
        case let .password(password):
            password
        case let .text(text):
            text
        }
    }
}

struct FullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .text
    @State private var originalBrightness: CGFloat = 0.5
    @State private var percentage: Double = 0.5
    let data: FullScreenData

    enum Mode {
        case text, qr

        var systemImageName: String {
            switch self {
            case .text:
                "textformat.abc"
            case .qr:
                "qrcode"
            }
        }

        var oppositeMode: Mode {
            switch self {
            case .text:
                .qr
            case .qr:
                .text
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PassColor.backgroundNorm
                    .ignoresSafeArea()

                Group {
                    switch mode {
                    case .text:
                        FullScreenTextView(percentage: $percentage,
                                           data: data)
                    case .qr:
                        QrCodeView(text: data.text)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.default, value: mode)
            .toolbar { toolbarContent }
        }
        .onAppear {
            originalBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = CGFloat(1.0)
        }
        .onDisappear {
            UIScreen.main.brightness = originalBrightness
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            CircleButton(icon: IconProvider.cross,
                         iconColor: PassColor.interactionNormMajor2,
                         backgroundColor: PassColor.interactionNormMinor1,
                         accessibilityLabel: "Close",
                         action: dismiss.callAsFunction)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                mode = mode.oppositeMode
            }, label: {
                Image(systemName: mode.oppositeMode.systemImageName)
                    .foregroundStyle(PassColor.interactionNorm)
            })
        }
    }
}

private struct FullScreenTextView: View {
    @Binding var percentage: Double
    let data: FullScreenData

    var body: some View {
        VStack {
            Spacer()

            switch data {
            case let .password(password):
                Text(password.coloredPassword())
                    .font(.system(size: (percentage + 1) * 24))
                    .fontWeight(.semibold)
            case let .text(text):
                Text(verbatim: text)
                    .font(.system(size: (percentage + 1) * 24))
                    .fontWeight(.semibold)
            }

            Spacer()
            HStack {
                Text(verbatim: "A")
                Slider(value: $percentage)
                    .tint(PassColor.interactionNorm)
                Text(verbatim: "A")
                    .font(.title)
            }
        }
        .foregroundStyle(PassColor.textNorm)
    }
}
